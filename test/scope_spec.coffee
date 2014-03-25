### 
jshint globalstrict: true
global Scope: false
###

console.debug "insanity!"

describe "Scope", ->

  it "can be constructed and used as an object", ->
    scope = new Scope()
    scope.aProperty = 1

    expect scope.aProperty
      .toBe 1

  describe "digest", ->

    scope = null

    beforeEach -> 
      scope = new Scope()
      for k, v of scope
        console.debug k
      return

    it "calls the listener function of a watch on first $digest", ->

      watchFn = -> "wat"
      listenerFn = jasmine.createSpy()

      scope.$watch watchFn, listenerFn

      scope.$digest()

      expect listenerFn
        .toHaveBeenCalled()

      return
