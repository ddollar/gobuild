async   = require("async")
coffee  = require("coffee-script")
dd      = require("./lib/dd")
express = require("express")
log     = require("./lib/logger").init("gobuild")
spawner = require("./lib/spawner").init()
stdweb  = require("./lib/stdweb")

app = stdweb("gobuild")

app.get "/:user/:repo/:ref/:os/:arch", (req, res) ->
  res.writeHead 200, "Content-Type":"application/octet-stream"
  version = req.params.ref
  version = version.substring(1) if version[0] is "v"
  env =
    GOARCH:  req.params.arch
    GOOS:    req.params.os
    PATH:    "/usr/local/bin:/usr/bin:/bin"
    REF:     req.params.ref
    VERSION: version
  ps = spawner.spawn "bin/build github.com/#{req.params.user}/#{req.params.repo}", env:env
  ps.on "data", (data) -> res.write data
  ps.on "end",         -> res.end()

app.start (port) -> console.log "listening on #{port}"
