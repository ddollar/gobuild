coffee  = require("coffee-script")
express = require("express")
log     = require("./logger").init("gobuild")

class Stdweb

  constructor: (@name) ->

  listen: (port=process.env.PORT) ->
    @app.use @app.router
    @app.listen port

module.exports = (name) ->
  app = express()
  app.disable "x-powered-by"

  express.logger.format "method",     (req, res) -> req.method.toLowerCase()
  express.logger.format "url",        (req, res) -> req.url.replace('"', "&quot")
  express.logger.format "user-agent", (req, res) -> (req.headers["user-agent"] || "").replace('"', "")

  app.use express.logger
    buffer: false
    format: "ns=\"banker\" measure=\"http.:method\" source=\":url\" status=\":status\" elapsed=\":response-time\" from=\":remote-addr\" agent=\":user-agent\""

  app.use express.cookieParser()
  app.use express.bodyParser()

  app.start = (port, cb) ->
    if port instanceof Function
      cb = port
      port = process.env.PORT
    @listen port, ->
      cb port

  app
