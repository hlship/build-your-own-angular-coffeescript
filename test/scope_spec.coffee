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

  describe "$digest", ->

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

    it "calls the listener when the watch value is initially undefined", ->

      scope.counter = 0

      watchFn = (scope) -> scope.someValue
      listenerFn = (newValue, oldValue, scope) -> scope.counter++

      scope.$watch watchFn, listenerFn

      scope.$digest()

      expect scope.counter
        .toBe 1

    it "triggers chained watchers in the same digest", ->

      scope.name ="Jane"

      scope.$watch ((scope) -> scope.name),
        (newValue, oldValue, scope) ->
          if newValue
            scope.nameUpper = newValue.toUpperCase()

      scope.$watch ((scope) -> scope.nameUpper),
        (newValue, oldValue, scope) ->
          if newValue
            scope.initial = newValue.substring(0, 1) + "."

      scope.$digest()

      expect scope.initial
        .toBe "J."

      scope.name = "Bob"
      scope.$digest()

      expect scope.initial
        .toBe "B."

    it "gives up on the watches after 10 iterations", ->

      scope.counterA = 0
      scope.counterB = 0

      scope.$watch ((scope) -> scope.counterA),
        (newValue, oldValue, scope) -> scope.counterB++

      scope.$watch ((scope) -> scope.counterB),
        (newValue, oldValue, scope) -> scope.counterA++

      expect (-> scope.$digest())
        .toThrow()

    it "ends the digest when the last watch is clean", ->

      scope.array = _.range 100

      watchExecutions = 0

      for i in [0..99]
          do (i) ->
            scope.$watch ((scope) -> 
                watchExecutions++
                scope.array[i]),
            (newValue, oldValue, scope) ->

      scope.$digest()

      expect watchExecutions
        .toBe 200

      scope.array[0] = 420

      scope.$digest()

      expect watchExecutions
        .toBe 301

    it "allows for new watches to be added inside listener functions", ->

      scope.aValue = "abc"
      scope.counter = 0

      scope
        .$watch (scope) -> scope.aValue,
        (newValue, oldValue, scope) ->
          scope
            .$watch (scope) -> scope.aValue,
            (newValue, oldValue, scope) -> scope.counter++

      scope.$digest()

      expect scope.counter
        .toBe 1

    it "compares based on value if enabled", ->

      scope.aValue = [1, 2, 3]
      scope.counter = 0

      scope
        .$watch (scope) -> scope.aValue,
        (newValue, oldValue, scope) -> scope.counter++,
        true

      scope.$digest()

      expect scope.counter
        .toBe 1

      # This wouldn't be a change for identity comparison (its the same Array)

      scope.aValue.push 4

      scope.$digest()

      expect scope.counter
        .toBe 2

    it "correctly handles NaNs", ->
      scope.number = 0/0 # NaN
      scope.counter = 0

      scope
        .$watch (scope) -> scope.number,
        (newValue, oldValue, scope) -> scope.counter++

      scope.$digest()

      expect scope.counter
        .toBe 1

      scope.$digest()

      expect scope.counter
        .toBe 1

  describe "$eval", -> 

    scope = null

    beforeEach -> 
      scope = new Scope()

    it "executes $eval'ed function and returns result", ->

      scope.aValue = 42

      expect scope.$eval (scope) -> scope.aValue
        .toBe 42

    it "passes the second $eval argument straight through", ->

      scope.aValue = 42

      expect scope.$eval ((scope, arg) -> scope.aValue + arg), 2
        .toBe 44

  describe "$apply", ->

    scope = null

    beforeEach -> 
      scope = new Scope()

    it "executes $apply'ed function and starts the digest", ->

      scope.aValue = "someValue"
      scope.counter = 0

      scope
        .$watch (scope) -> scope.aValue,
        (newValue, oldValue, scope) -> scope.counter++

      scope.$digest()

      expect scope.counter
        .toBe 1

      scope.$apply (scope) -> scope.aValue = "new value"

      expect scope.counter
        .toBe 2
