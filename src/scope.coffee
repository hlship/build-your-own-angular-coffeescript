###
jshint globalstrict: true
###

@Scope = ->
  @$$watchers = []
  @$$lastDirtyWatch = null

# This isn't called, its used as a kind of private substitute for undefined
# to ensure that listener is invoked on the first digest. Functions always
# compare as not-equal.

initWatchVal = ->

@Scope::$watch = (watchFn, listenerFn, valueEq) ->
  @$$watchers.unshift {
    watchFn: watchFn
    listenerFn: listenerFn
    valueEq: valueEq is true
    last: initWatchVal}
  @$$lastDirtyWatch = null

  return this

areEqual = (newValue, oldValue, valueEq) ->
  return _.isEqual newValue, oldValue if valueEq
  
  (newValue is oldValue) or
  (typeof newValue is "number" and
   typeof oldValue is "number" and
   isNaN(newValue) and
   isNaN(oldValue))

@Scope::$digest = ->

  @$$lastDirtyWatch = null
  for i in [1..10]
    return this unless @$$digestOnce()

  throw Error "$digest did not settle after 10 iterations"

@Scope::$$digestOnce = ->  
  dirty = false
  length = @$$watchers.length
  while length--
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

  return dirty

@Scope::$eval = (expr, locals) ->
  expr this, locals