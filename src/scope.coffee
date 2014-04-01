###
jshint globalstrict: true
###


## For some reason, Scope = -> doesn't quite do the right thing.
`
function Scope() { 
  this.$$watchers = [];
}
`

### 
@Scope = ->
  @$$watchers = []
  @$$lastDirtyWatch = null
###

# This isn't called, its used as a kind of private substitute for undefined
# to ensure that listener is invoked on the first digest. Functions always
# compare as not-equal.

initWatchVal = ->

Scope::$watch = (watchFn, listenerFn) ->
  @$$watchers.unshift {watchFn, listenerFn, last: initWatchVal}
  @$$lastDirtyWatch = null
  
  return this

Scope::$digest = ->

  @$$lastDirtyWatch = null
  for i in [1..10]
    return this unless @$$digestOnce()

  throw Error "$digest did not settle after 10 iterations"

Scope::$$digestOnce = ->  
  dirty = false
  length = @$$watchers.length
  while length--
    watcher = @$$watchers[length]
    newValue = watcher.watchFn this
    oldValue = watcher.last

    unless newValue is oldValue
      dirty = true
      @$$lastDirtyWatch = watcher
      watcher.last = newValue
      watcher.listenerFn newValue, oldValue, this
    else if @$$lastDirtyWatch is watcher
      return false

  return dirty
