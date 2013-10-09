async   = require("async")
coffee  = require("coffee-script")
dd      = require("./lib/dd")
events  = require("events")
express = require("express")
log     = require("./lib/logger").init("gobuild")
spawner = require("./lib/spawner").init()
stdweb  = require("./lib/stdweb")
uuid    = require("node-uuid")

app = stdweb("gobuild")

reader = require("redis-url").connect(process.env.REDIS_URL)
writer = require("redis-url").connect(process.env.REDIS_URL)

builds = {}

reader.on "message", (channel, message) ->
  [_, id, channel] = channel.split(":")
  res = builds[id]
  switch channel
    when "data"
      res.write new Buffer(message, "base64")
    when "end"
      res.end()
      reader.unsubscribe "build:#{id}:data"
      reader.unsubscribe "build:#{id}:end"

app.get "/:user/:repo/:ref/:os/:arch", (req, res) ->
  id = uuid.v4()
  builds[id] = res
  version = req.params.ref
  version = version.substring(1) if version[0] is "v"
  log.start "build", id:id.split("-").pop(), version:version, project:"#{req.params.user}/#{req.params.repo}", (log) ->
    log.write_status "start"
    res.writeHead 200, "Content-Type":"application/octet-stream", "Build-Id":id
    res.write ""
    env =
      BUILD_ID:   id
      BUILD_HOST: process.env.BUILD_HOST
      GOARCH:     req.params.arch
      GOOS:       req.params.os
      PATH:       "/usr/local/bin:/usr/bin:/bin"
      REF:        req.params.ref
      VERSION:    version
    ps = spawner.spawn "bin/build github.com/#{req.params.user}/#{req.params.repo}", env:env
    ps.on "connect",     -> log.write_status "connected"
    ps.on "data", (data) ->
      writer.append "build:#{id}:output", data.toString()
      for line in data.toString().replace(/\s+$/g, "").split("\n")
        log.write_status "output", line:line
    ps.on "end",         -> log.write_status "end"; res.end()
    reader.subscribe "build:#{id}:data"
    reader.subscribe "build:#{id}:end"

app.get "/build/:id/output", (req, res) ->
  reader.get "build:#{req.params.id}:output", (err, output) ->
    res.send output

app.put "/build/:id/binary", (req, res) ->
  id = req.params.id
  req.on "data", (data) -> writer.publish "build:#{id}:data", data.toString("base64")
  req.on "end",         -> writer.publish "build:#{id}:end", ""; res.end()

app.start (port) -> console.log "listening on #{port}"
