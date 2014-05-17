### 
jshint globalstrict: true
global Scope: false
###

describe "Scope", ->

  watchAValue = (s) -> s.aValue
  incrementCounter = (newValue, oldValue, s) -> s.counter++
  noop = ->

  scope = null

  beforeEach -> 
    scope = new Scope()

  it "can be constructed and used as an object", ->
    newScope = new Scope()
    newScope.aProperty = 1

    expect newScope.aProperty
      .toBe 1

  it "has a $$phase field whose value is the current digest phase", ->

    scope.aValue = [1, 2, 3]
    scope.phases = {}

    scope.$watch ((scope) ->
        scope.phases.inWatch = scope.$$phase
        scope.aValue),
      (newValue, oldValue, scope) ->
        scope.phases.inListener = scope.$$phase

    scope.$apply (scope) ->
      scope.phases.inApply = scope.$$phase

    expect scope.phases.inWatch
      .toBe "$digest"

    expect scope.phases.inListener
      .toBe "$digest"

    expect scope.phases.inApply
      .toBe "$apply"

  describe "$new", ->

    it "inherits the parent's properties", ->

      parent = new Scope()
      parent.aValue = [1, 2, 3]

      child = parent.$new()

      expect child.aValue
        .toEqual [1, 2, 3]

    it "does not cause a parent to inherit the child's properties", ->

       parent = new Scope()

       child = parent.$new()

       child.aValue = [1, 2, 3]

       expect parent.aValue
        .toBeUndefined()

    it "inherits the parent's properties whenever they are defined", ->

      parent = new Scope()

      child = parent.$new()

      parent.aValue = [1, 2, 3]

      expect child.aValue
        .toEqual [1, 2, 3]

    it "can manipulate a parent scope's property", ->

      parent = new Scope()

      child = parent.$new()

      parent.aValue = [1, 2, 3]

      child.aValue.push 4

      expect child.aValue
        .toEqual [1, 2, 3, 4]

      expect parent.aValue
        .toEqual [1, 2, 3, 4]

    it "can watch a property in the parent", ->

      parent = new Scope()
      child = parent.$new()

      parent.aValue = [1, 2, 3]

      child.counter = 0

      child.$watch watchAValue, incrementCounter, true

      child.$digest()

      expect child.counter
        .toBe 1

      parent.aValue.push 4

      child.$digest()

      expect child.counter
        .toBe 2

    it "can be nested at any depth", ->

      a = new Scope()
      aa = a.$new()
      aaa = aa.$new()
      aab = aa.$new()
      ab = a.$new()
      abb = ab.$new()

      a.value = 1

      for scope in [aa, aaa, aab, ab, abb]
        expect scope.value
          .toBe 1

      ab.anotherValue = 2

      expect abb.anotherValue
        .toBe 2

      expect aa.anotherValue
        .toBeUndefined()

      expect aaa.anotherValue
        .toBeUndefined()

    it "shadows a parent's property with the same name", ->

      parent = new Scope()
      child = parent.$new()

      parent.name = "Joe"
      child.name = "Jill"

      expect child.name
        .toBe "Jill"

      expect parent.name
        .toBe "Joe"

    it "keeps a record of its children", ->

      parent = new Scope()

      child1 = parent.$new()
      child2 = parent.$new()
      child2_1 = child2.$new()

      expect parent.$$children
        .toEqual [child1, child2]

      expect child1.$$children.length
        .toBe 0

      expect child2.$$children
        .toEqual [child2_1]

  describe "$digest", ->

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

      scope.aValue = "a"
      scope.counter = 0

      scope.$watch watchAValue, incrementCounter

      expect scope.counter
        .toBe 0

      scope.$digest()

      expect scope.counter
        .toBe 1

      scope.$digest()

      expect scope.counter
        .toBe 1
      
      scope.aValue = "b"

      scope.$digest()

      expect scope.counter
        .toBe 2

    it "calls the listener when the watch value is initially undefined", ->

      scope.counter = 0

      scope.$watch watchAValue, incrementCounter

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

      scope.$watch watchAValue,
        (newValue, oldValue, scope) ->
          scope.$watch watchAValue, incrementCounter

      scope.$digest()

      expect scope.counter
        .toBe 1

    it "compares based on value if enabled", ->

      scope.aValue = [1, 2, 3]
      scope.counter = 0

      scope.$watch watchAValue, incrementCounter, true

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

      scope.$watch ((scope) -> scope.number), incrementCounter

      scope.$digest()

      expect scope.counter
        .toBe 1

      scope.$digest()

      expect scope.counter
        .toBe 1

    it "catches exceptions in watch functions, and continues", ->

      scope.aValue = "abc"
      scope.counter = 0

      scope.$watch ((scope) -> throw Error "error"), ->

      scope.$watch watchAValue, incrementCounter
        
      scope.$digest()
      expect scope.counter
        .toBe 1

    it "catches exceptions in listener functions, and continues", ->

      scope.aValue = "abc"
      scope.counter = 0

      scope.$watch watchAValue, (newValue, oldValue, scope) -> throw Error "error"

      scope.$watch watchAValue, incrementCounter

      scope.$digest()
      expect scope.counter
        .toBe 1

    it "allows destroying a $watch via the returned removal function", ->

      scope.aValue = "abc"
      scope.counter = 0

      destroyer = scope.$watch watchAValue, incrementCounter

      scope.$digest()

      expect scope.counter
        .toBe 1

      scope.aValue = "def"

      scope.$digest()

      expect scope.counter
        .toBe 2

      scope.aValue = "ghi"
      destroyer()

      scope.$digest()

      expect scope.counter
        .toBe 2

    it "allows destroying a $watch during digest", ->

      scope.aValue = "abc"
      scope.counter = 0

      # Problem: this works, but there's a logged error because watcher.listenerFn is undefined
      destroy = scope.$watch -> 
        destroy()
        return

      scope.$watch watchAValue, incrementCounter

      scope.$digest()
      expect scope.counter
        .toBe 1

    it "allows a $watch to dstroy another during digest", ->

      scope.aValue = "abc"
      scope.counter = 0

      scope.$watch watchAValue, -> destroyWatch()

      destroyWatch = scope.$watch noop, noop

      scope.$watch watchAValue, incrementCounter

      scope.$digest()

      expect scope.counter
        .toBe 1

    it "allows destroying several $watches during digest", ->

      scope.aValue = "abc"
      scope.counter = 0

      destroy1 = scope.$watch ->
        destroy1()
        destroy2()

      destroy2 = scope.$watch watchAValue, incrementCounter

      scope.$digest()

      expect scope.counter
        .toBe 0

    it "does not digest its parent(s)", ->

      parent = new Scope()
      child = parent.$new()

      parent.aValue = "abc"

      parent.$watch watchAValue, (newValue, oldValue, scope) -> scope.aValueWas = newValue

      child.$digest()

      expect child.aValueWas
        .toBeUndefined()

    it "digests its children", ->

      parent = new Scope()
      child = parent.$new()

      parent.aValue = "abc"

      child.$watch watchAValue, (newValue, oldValue, scope) -> scope.aValueWas = newValue

      parent.$digest()

      expect child.aValueWas
        .toBe "abc"

  describe "$eval", -> 

    it "executes $eval'ed function and returns result", ->

      scope.aValue = 42

      expect scope.$eval (scope) -> scope.aValue
        .toBe 42

    it "passes the second $eval argument straight through", ->

      scope.aValue = 42

      expect scope.$eval ((scope, arg) -> scope.aValue + arg), 2
        .toBe 44

  describe "$apply", ->

    it "executes $apply'ed function and starts the digest", ->

      scope.aValue = "someValue"
      scope.counter = 0

      scope.$watch watchAValue, incrementCounter

      scope.$digest()

      expect scope.counter
        .toBe 1

      scope.$apply (scope) -> scope.aValue = "new value"

      expect scope.counter
        .toBe 2

    it "digests from root on $apply", ->

      parent = new Scope()
      child = parent.$new()
      child2 = child.$new()

      parent.aValue = "abc"
      parent.counter = 0

      parent.$watch watchAValue, incrementCounter

      child2.$apply ->

      expect parent.counter
        .toBe 1



  describe "$evalAsync", ->

    it "executes $evalAsync'ed function later in the same cycle", ->

      scope.aValue = [1, 2, 3]
      scope.asyncEvaluated = false
      scope.asyncEvaluatedImmediately = false

      scope.$watch watchAValue,
        (newValue, oldValue, scope) ->
          scope.$evalAsync (scope) -> scope.asyncEvaluated = true
          scope.asyncEvaluatedImmediately = scope.asyncEvaluated

      scope.$digest()

      expect scope.asyncEvaluated
        .toBe true

      expect scope.asyncEvaluatedImmediately
        .toBe false

    it "executes $evalAsync'ed functions added by watch functions", ->
      scope.aValue = [1, 2, 3]
      scope.asyncEvaluated = false

      scope.$watch ((scope) ->
          unless scope.asyncEvaluated
            scope.$evalAsync (scope) -> scope.asyncEvaluated = true
          return scope.aValue),
        (newValue, oldValue, scope) ->

      scope.$digest()

      expect scope.asyncEvaluated
        .toBe true

    it "eventually halts $evalAsync added by watches", ->

      scope.aValue = [1, 2, 3]

      scope.$watch ((scope) ->
        scope.$evalAsync ->
        scope.aValue),
        ->

      expect -> scope.$digest()
        .toThrow()

    it "schedules a digest in $evalAsync", (done) ->

      scope.aValue = "abc"
      scope.counter = 0

      scope.$watch watchAValue, incrementCounter

      scope.$evalAsync ->

      # Since $evalAsync defers its digest, we don't expect
      # to see it yet.
      expect scope.counter
        .toBe 0

      setTimeout (->
        expect scope.counter
          .toBe 1
        done()
      ), 50 # ms later 

    it "schedules a digest from root in $evalAsync", (done) ->

      parent = new Scope()
      child = parent.$new()
      child2 = child.$new()

      parent.aValue = "abc"
      parent.counter = 0

      parent.$watch watchAValue, incrementCounter

      child2.$evalAsync ->

      setTimeout (->

        expect parent.counter
          .toBe 1

        done()

        ), 50

    it "caches exceptions in $evalAsync", (done) ->

      scope.aValue = "abc"
      scope.counter = 0;

      scope.$watch watchAValue, incrementCounter

      scope.$evalAsync -> throw Error "error"

      setTimeout (->
        expect scope.counter
          .toBe 1
        done()
      ), 50

  describe "$$postDigest", ->

    it "runs a $$postDigest function after each digest", ->

      scope.counter = 0

      # Post digest function is NOT passed the scope.
      scope.$$postDigest -> scope.counter++

      expect scope.counter
        .toBe 0

      scope.$digest()

      expect scope.counter
        .toBe 1

      scope.$digest()

      # $$postDigest functions are invoked once then discarded

      expect scope.counter
        .toBe 1

    it "does not include $$postDigest in the digest", ->

      scope.aValue = "original"

      scope.$$postDigest -> scope.aValue = "changed"

      scope.$watch watchAValue,
        (newValue, oldValue, scope) -> scope.watchedValue = newValue

      scope.$digest()
      expect scope.watchedValue
        .toBe "original"

      scope.$digest()
      expect scope.watchedValue
        .toBe "changed"

    it "catches exceptions in $$postDigest", ->

      didRun = false

      scope.$$postDigest -> throw Error "error"
      scope.$$postDigest -> didRun = true

      scope.$digest()

      expect didRun
        .toBe true


