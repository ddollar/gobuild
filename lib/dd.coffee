coffee = require("coffee-script")

module.exports =

  arrayify: (obj) -> if Array.isArray(obj) then obj else [obj]

  delay: (ms, cb) -> setTimeout cb, ms

  every: (ms, cb) -> setInterval cb, ms

  firstkey: (obj) -> obj[@keys(obj)[0]]

  keys: (hash) -> key for key, val of hash

  merge: coffee.helpers.merge

  reduce: (obj, start, cb) -> obj.reduce(cb, start)

  values: (hash) -> (val for key, val of hash)
