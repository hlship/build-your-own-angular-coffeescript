###
jshint globalstrict: true
###

initScope = (scope) ->

  scope.$$watchers = []
  scope.$$children = []
  scope.$$listeners = {}

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

  return

@Scope::$$everyScope = (fn) ->

  if fn this
    @$$children.every (child) -> child.$$everyScope fn
  else
    false

@Scope::$beginPhase = (phase) ->
  if @$$phase
    throw Error "can't start phase '#{phase}' when '#{@$$phase} is already in progress"

  @$$phase = phase

  return

@Scope::$clearPhase = -> 
  @$$phase = null
  return

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
    return

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

  return

@Scope::$evalAsync = (expr) ->

  # When there is no digest currently AND
  # the queue is empty, then schedule a $digest for later.

  if not (@$$phase or @$$asyncQueue.length)
    setTimeout (=> @$$root.$digest()), 0

  @$$asyncQueue.push 
    scope: this
    expression: expr

  return

@Scope::$$postDigest = (callback) ->
  @$$postDigestQueue.push callback

  return

@Scope::$watchCollection = (watchFn, listenerFn) ->

  thisScope = this
  newValue = null
  oldValue = null
  oldLength = 0
  changeCount = 0
  # Tracking the old value is expensive (a copy must be made!)
  # so we only do it if the listener function has more than one
  # parameter (parameter #2 is the oldValue).
  trackVeryOldValue = listenerFn.length > 1
  veryOldValue = null
  firstListenerInvocation = true

  internalWatchFn = (scope) ->

    newValue = watchFn scope

    if _.isObject newValue

        if _.isArrayLike newValue

          if not _.isArray oldValue
            changeCount++
            oldValue = []

          if newValue.length isnt oldValue.length
            changeCount++
            oldValue.length = newValue.length

          # Now look for differences between the two arrays

          _.forEach newValue, (newItem, i) ->

            bothNaN = (_.isNaN newItem) and (_.isNaN oldValue[i])

            if (not bothNaN) and (newItem isnt oldValue[i])
              changeCount++
              oldValue[i] = newItem

            return

        else
          if (not _.isObject oldValue) or (_.isArrayLike oldValue)
            changeCount++
            oldValue = {}
            oldLength = 0

          newLength = 0

          _.forOwn newValue, (newVal, key) ->
            newLength++
            if oldValue.hasOwnProperty key
              bothNaN = (_.isNaN newVal) and (_.isNaN oldValue[key])
              if (not bothNaN) and (oldValue[key] isnt newVal)
                changeCount++
                oldValue[key] = newVal
            else
              changeCount++
              oldLength++
              oldValue[key] = newVal
            return

          if oldLength > newLength
            changeCount++
            _.forOwn oldValue, (oldVal, key) ->
              if (not newValue.hasOwnProperty key)
                delete oldValue[key]
                oldLength--
              return

    else

      # Non-collection value
      if (not areEqual newValue, oldValue, false)
        changeCount++

      # BYOA mentions how this is Angular's current behavior, even though in
      # conflicts with both expectations and documentation.

      oldValue = newValue

    return changeCount


  internalListenerFn = =>

    if firstListenerInvocation
      listenerFn newValue, newValue, thisScope
      firstListenerInvocation = false
    else
      listenerFn newValue, veryOldValue, thisScope

    if trackVeryOldValue
      veryOldValue = _.clone newValue

  @$watch internalWatchFn, internalListenerFn

  return


@Scope::$on = (eventName, listener) ->
  eventListeners = @$$listeners[eventName]
  if not eventListeners
    @$$listeners[eventName] = [listener]
  else
    eventListeners.push listener
  return
