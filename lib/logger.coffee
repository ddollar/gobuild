coffee = require("coffee-script")
uuid   = require("node-uuid")

class Logger

  constructor: (@ns, @options={}) ->

  write: (options={}) ->
    opts = coffee.helpers.merge(ns:@ns, options)
    message = ("#{key}=\"#{(if val? then val else "").toString().replace('"', '\\"')}\"" for key, val of opts)
    console.log message.join(" ")

  write_status: (status, options={}) ->
    opts = coffee.helpers.merge(@options, options)
    opts.measure = "#{opts.measure}.#{status}"
    if @started
      opts.value = (new Date().getTime()) - @started
      opts.units = "ms"
    @write opts

  log: (opts={}, cb) ->
    options = coffee.helpers.merge(@options, opts)
    options.txn = uuid.v1().split("-")[0] if options.txn is true
    if cb?
      logger = new Logger(@ns, options)
      logger.start = new Date().getTime()
      cb(logger)
    else
      @write options

  finish: (opts={}) ->
    options = coffee.helpers.merge(@options, opts)
    finish  = new Date().getTime()
    elapsed = finish - @start
    @write coffee.helpers.merge(options, value:elapsed, units:"ms")

  start: (measure, options={}, cb) ->
    if options instanceof Function
      cb = options
      options = {}
    if options.txn is true
      options.txn = uuid.v1().split("-")[0]
    opts = coffee.helpers.merge(@options, options)
    opts.measure = measure
    logger = new Logger(@ns, opts)
    logger.started = (new Date().getTime())
    logger.measure = measure
    cb logger if logger

  success: (options={}) ->
    @write_status "success", options

  failure: (message, options={}) ->
    @write_status "failure", coffee.helpers.merge(options, message:message)

  delay: (delay, options={}) ->
    @write_status "delay", options

  error: (err, opts={}) ->
    id = uuid.v1().split("-")[0]
    options =
      id:      id,
      name:    err.name,
      message: err.message
    options = coffee.helpers.merge(@options, options)
    options = coffee.helpers.merge(options, opts)
    @write_status "error", options
    if err.stack
      for idx, line of err.stack.split("\n")
        @write at:"error", id:id, line:idx, trace:line
    err

  coerce_error: (err) ->
    if err instanceof Error
      err
    else if typeof(err) is "string"
      new Error(err)
    else
      str = ""
      str += v for k, v of err
      new Error(str)

  measure: (name, value, options={}) ->
    @write coffee.helpers.merge(measure:name, value:value, options)

module.exports.init = (ns, options={}) ->
  new Logger(ns)
