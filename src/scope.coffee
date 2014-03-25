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
  for w in @$$watchers
    w.listenerFn()
  return this
