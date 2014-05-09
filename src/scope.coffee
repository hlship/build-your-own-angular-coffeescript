###
jshint globalstrict: true
###

@Scope = ->
  @$$watchers = []
  @$$lastDirtyWatch = null
  @$$asyncQueue = []
  @$$phase = null
  @$$postDigestQueue = []

  return

@Scope::$beginPhase = (phase) ->
  if @$$phase
    throw Error "can't start phase '#{phase}' when '#{@$$phase} is already in progress"

  @$$phase = phase

@Scope::$clearPhase = -> @$$phase = null

# This isn't called, its used as a kind of private substitute for undefined
# to ensure that listener is invoked on the first digest. Functions always
# compare as not-equal.

initWatchVal = ->

@Scope::$watch = (watchFn, listenerFn, valueEq) ->
  watcher =
    watchFn: watchFn
    listenerFn: listenerFn
    valueEq: valueEq is true
    last: initWatchVal
  
  @$$watchers.unshift watcher

  @$$lastDirtyWatch = null

  =>
    ix = @$$watchers.indexOf watcher
    @$$watchers.splice ix, 1 if ix >= 0

areEqual = (newValue, oldValue, valueEq) ->
  return _.isEqual newValue, oldValue if valueEq
  
  (newValue is oldValue) or
  (typeof newValue is "number" and
   typeof oldValue is "number" and
   isNaN(newValue) and
   isNaN(oldValue))

@Scope::$digest = ->

  @$beginPhase "$digest"

  try
    ttl = 10
    @$$lastDirtyWatch = null
    busy = true
    while busy
      while @$$asyncQueue.length
        task = @$$asyncQueue.shift()
        try
          task.scope.$eval task.expression
        catch e
          console.error e

      busy = @$$digestOnce() or @$$asyncQueue.length
      if busy and --ttl is 0
        throw Error "$digest did not settle after 10 iterations"
  finally
    @$clearPhase()

  while @$$postDigestQueue.length
    callback = @$$postDigestQueue.shift()

    try
      callback()
    catch e
      console.error e

  return

@Scope::$$digestOnce = ->  
  dirty = false
  length = @$$watchers.length
  while length--
    try
      watcher = @$$watchers[length]
      newValue = watcher.watchFn this
      oldValue = watcher.last
      valueEq = watcher.valueEq

      unless areEqual newValue, oldValue, valueEq
        dirty = true
        @$$lastDirtyWatch = watcher
        watcher.last = if valueEq
                          _.cloneDeep newValue
                       else
                          newValue
        watcher.listenerFn newValue, oldValue, this
      else if @$$lastDirtyWatch is watcher
        return false
    catch e
      console.error e

  return dirty

@Scope::$eval = (expr, locals) ->
  expr this, locals

@Scope::$apply = (expr) ->
  try
    @$beginPhase "$apply"
    @$eval expr
  finally
    @$clearPhase()
    @$digest()

@Scope::$evalAsync = (expr) ->

  # When there is no digest currently AND
  # the queue is empty, then schedule a $digest for later.

  if not (@$$phase or @$$asyncQueue.length)
    setTimeout (=> @$digest()), 0

  @$$asyncQueue.push 
    scope: this
    expression: expr

@Scope::$$postDigest = (callback) ->
  @$$postDigestQueue.push callback
    