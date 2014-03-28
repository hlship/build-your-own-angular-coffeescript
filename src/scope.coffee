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

Scope::$watch = (watchFn, listenerFn) ->
  @$$watchers.unshift {watchFn, listenerFn}
  return this

Scope::$digest = ->  
  for watcher in @$$watchers
    newValue = watcher.watchFn this
    oldValue = watcher.last

    unless newValue is oldValue
      watcher.last = newValue
      watcher.listenerFn newValue, oldValue, this

  return this
