###
jshint globalstrict: true
###

initScope = (scope) ->

  scope.$$watchers = []
  scope.$$children = []

  return scope


@Scope = ->
  @$$root = this
  @$$lastDirtyWatch = null
  @$$asyncQueue = []
  @$$phase = null
  @$$postDigestQueue = []

  initScope this

@Scope::$new = (isolated) ->

  child = null

  if isolated
    child = new Scope()
    # My take on this, is that Scope should be split into two parts, with
    # a link to all this data shared between parents and isolated children.
    # So that there's only one property to shadow into a isolated scope.
    child.$$root = @$$root
    child.$$lastDirtyWatch = @$$lastDirtyWatch
    child.$$asyncQueue = @$$asyncQueue
    child.$$postDigestQueue = @$$postDigestQueue
  else
    ChildScope = ->
    ChildScope.prototype = this

    child = new ChildScope()

  @$$children.push child

  child.$parent = this

  initScope child

@Scope::$destroy = ->

  return if this is @$$root

  siblings = @$parent.$$children

  ix = siblings.indexOf this

  siblings.splice ix, 1 if ix >= 0


@Scope::$$everyScope = (fn) ->

  if fn this
    @$$children.every (child) -> child.$$everyScope fn
  else
    false

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
    if ix >= 0
      @$$watchers.splice ix, 1 
      @$$lastDirtyWatch = null

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
  
  @$$everyScope (scope) =>

    # This is ugly and hard to follow in both CoffeeScript and JavaScript.
    _.forEachRight scope.$$watchers, (watcher) =>
      try
        if watcher
          newValue = watcher.watchFn scope
          oldValue = watcher.last
          valueEq = watcher.valueEq

          unless areEqual newValue, oldValue, valueEq
            @$$root.$$lastDirtyWatch = watcher
            watcher.last = if valueEq
                              _.cloneDeep newValue
                           else
                              newValue
            watcher.listenerFn newValue, oldValue, scope
            dirty = true
          else if @$$root.$$lastDirtyWatch is watcher
            dirty = false
            return false
            
          return
      catch e
        console.error e
        return

    true

  dirty

@Scope::$eval = (expr, locals) ->
  expr this, locals

@Scope::$apply = (expr) ->
  try
    @$beginPhase "$apply"
    @$eval expr
  finally
    @$clearPhase()
    @$$root.$digest()

@Scope::$evalAsync = (expr) ->

  # When there is no digest currently AND
  # the queue is empty, then schedule a $digest for later.

  if not (@$$phase or @$$asyncQueue.length)
    setTimeout (=> @$$root.$digest()), 0

  @$$asyncQueue.push 
    scope: this
    expression: expr

@Scope::$$postDigest = (callback) ->
  @$$postDigestQueue.push callback
    