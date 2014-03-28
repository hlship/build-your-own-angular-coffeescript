### 
jshint globalstrict: true
global Scope: false
###

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

    it "calls the listener function of a watch on first $digest", ->

      watchFn = -> "wat"
      listenerFn = jasmine.createSpy()

      scope.$watch watchFn, listenerFn

      scope.$digest()

      expect listenerFn
        .toHaveBeenCalled()

    it "calls the watch function with the scope as the argument", ->

      watchFn = jasmine.createSpy()
      listenerFn = ->

      scope.$watch watchFn, listenerFn

      scope.$digest()

      expect watchFn
        .toHaveBeenCalledWith scope

    it "calls the listener function when the watched value changes", ->

      scope.someValue = "a"
      scope.counter = 0

      watchFn = (scope) -> scope.someValue
      listenerFn = (newValue, oldValue, scope) -> scope.counter++

      scope.$watch watchFn, listenerFn

      expect scope.counter
        .toBe 0

      scope.$digest()

      expect scope.counter
        .toBe 1

      scope.$digest()

      expect scope.counter
        .toBe 1
      
      scope.someValue = "b"

      scope.$digest()

      expect scope.counter
        .toBe 2