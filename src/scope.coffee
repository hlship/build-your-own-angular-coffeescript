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
###

# This isn't called, its used as a kind of private substitute for undefined
# to ensure that listener is invoked on the first digest. Functions always
# compare as not-equal.

initWatchVal = ->

Scope::$watch = (watchFn, listenerFn) ->
  @$$watchers.unshift {watchFn, listenerFn, last: initWatchVal}
  return this

Scope::$digest = ->  
  for watcher in @$$watchers
    newValue = watcher.watchFn this
    oldValue = watcher.last

    unless newValue is oldValue
      watcher.last = newValue
      watcher.listenerFn newValue, oldValue, this

  return this
