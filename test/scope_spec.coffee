### 
jshint globalstrict: true
global Scope: false
###



describe "Scope", ->

  watchAValue = (s) -> s.aValue
  incrementCounter = (newValue, oldValue, s) -> s.counter++
  storeAValueWas = (newValue, oldValue, s)-> s.aValueWas = newValue
  noop = ->

  later = (done, f) ->
    setTimeout (->
      f()
      done()
    ), 50

  scope = null

  beforeEach -> 
    scope = new Scope()

  # Most of the tests do something to the scope, run $digest,
  # then check the counter (via the incrementCounter callback).
  expectCounterAfterDigest = (expectedCount) ->
    scope.$digest()

    expect scope.counter
      .toBe expectedCount

  it "can be constructed and used as an object", ->

    newScope = new Scope()
    newScope.aProperty = 1

    expect newScope.aProperty
      .toBe 1

  it "has a $$phase field whose value is the current digest phase", ->

    scope.aValue = [1, 2, 3]
    scope.phases = {}

    scope.$watch ((s) ->
        s.phases.inWatch = scope.$$phase
        s.aValue),
      (newValue, oldValue, s) ->
        s.phases.inListener = s.$$phase

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

      expectCounterAfterDigest 1

      expectCounterAfterDigest 1
      
      scope.aValue = "b"

      expectCounterAfterDigest 2

    it "calls the listener when the watch value is initially undefined", ->

      scope.counter = 0

      scope.$watch watchAValue, incrementCounter

      expectCounterAfterDigest 1

    it "triggers chained watchers in the same digest", ->

      scope.name ="Jane"

      scope.$watch ((s) -> s.name),
        (newValue, oldValue, s) ->
          if newValue
            s.nameUpper = newValue.toUpperCase()

      scope.$watch ((s) -> s.nameUpper),
        (newValue, oldValue, s) ->
          if newValue
            s.initial = newValue.substring(0, 1) + "."

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

      scope.$watch ((s) -> s.counterA),
        (newValue, oldValue, s) -> s.counterB++

      scope.$watch ((s) -> s.counterB),
        (newValue, oldValue, s) -> s.counterA++

      expect (-> scope.$digest())
        .toThrow()

    it "ends the digest when the last watch is clean", ->

      scope.array = _.range 100

      watchExecutions = 0

      for i in [0..99]
          do (i) ->
            scope.$watch ((s) -> 
                watchExecutions++
                s.array[i]),
            (newValue, oldValue, s) ->

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
        (newValue, oldValue, s) ->
          s.$watch watchAValue, incrementCounter

      expectCounterAfterDigest 1

    it "compares based on value if enabled", ->

      scope.aValue = [1, 2, 3]
      scope.counter = 0

      scope.$watch watchAValue, incrementCounter, true

      expectCounterAfterDigest 1

      # This wouldn't be a change for identity comparison (its the same Array)

      scope.aValue.push 4

      expectCounterAfterDigest 2


    it "correctly handles NaNs", ->
      scope.number = 0/0 # NaN
      scope.counter = 0

      scope.$watch ((s) -> s.number), incrementCounter

      expectCounterAfterDigest 1

      expectCounterAfterDigest 1

    it "catches exceptions in watch functions, and continues", ->

      scope.aValue = "abc"
      scope.counter = 0

      scope.$watch ((s) -> throw Error "error"), ->

      scope.$watch watchAValue, incrementCounter
        
      expectCounterAfterDigest 1


    it "catches exceptions in listener functions, and continues", ->

      scope.aValue = "abc"
      scope.counter = 0

      scope.$watch watchAValue, (newValue, oldValue, s) -> throw Error "error"

      scope.$watch watchAValue, incrementCounter

      expectCounterAfterDigest 1

    it "allows destroying a $watch via the returned removal function", ->

      scope.aValue = "abc"
      scope.counter = 0

      destroyer = scope.$watch watchAValue, incrementCounter

      expectCounterAfterDigest 1

      scope.aValue = "def"

      expectCounterAfterDigest 2

      scope.aValue = "ghi"
      destroyer()

      expectCounterAfterDigest 2


    it "allows destroying a $watch during digest", ->

      scope.aValue = "abc"
      scope.counter = 0

      # Problem: this works, but there's a logged error because watcher.listenerFn is undefined
      destroy = scope.$watch -> 
        destroy()
        return

      scope.$watch watchAValue, incrementCounter

      expectCounterAfterDigest 1

    it "allows a $watch to dstroy another during digest", ->

      scope.aValue = "abc"
      scope.counter = 0

      scope.$watch watchAValue, -> destroyWatch()

      destroyWatch = scope.$watch noop, noop

      scope.$watch watchAValue, incrementCounter

      expectCounterAfterDigest 1

    it "allows destroying several $watches during digest", ->

      scope.aValue = "abc"
      scope.counter = 0

      destroy1 = scope.$watch ->
        destroy1()
        destroy2()

      destroy2 = scope.$watch watchAValue, incrementCounter

      expectCounterAfterDigest 0

    it "does not digest its parent(s)", ->

      parent = new Scope()
      child = parent.$new()

      parent.aValue = "abc"

      parent.$watch watchAValue, storeAValueWas

      child.$digest()

      expect child.aValueWas
        .toBeUndefined()

    it "digests its children", ->

      parent = new Scope()
      child = parent.$new()

      parent.aValue = "abc"

      child.$watch watchAValue, storeAValueWas

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

      expectCounterAfterDigest 1

      scope.$apply (s) -> s.aValue = "new value"

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
        (newValue, oldValue, s) ->
          scope.$evalAsync (s) -> s.asyncEvaluated = true
          scope.asyncEvaluatedImmediately = s.asyncEvaluated

      scope.$digest()

      expect scope.asyncEvaluated
        .toBe true

      expect scope.asyncEvaluatedImmediately
        .toBe false

    it "executes $evalAsync'ed functions added by watch functions", ->
      scope.aValue = [1, 2, 3]
      scope.asyncEvaluated = false

      scope.$watch ((s) ->
          unless s.asyncEvaluated
            s.$evalAsync (_s) -> _s.asyncEvaluated = true
          return s.aValue),
        (newValue, oldValue, s) ->

      scope.$digest()

      expect scope.asyncEvaluated
        .toBe true

    it "eventually halts $evalAsync added by watches", ->

      scope.aValue = [1, 2, 3]

      scope.$watch ((s) ->
        s.$evalAsync ->
        s.aValue),
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

      later done, ->
        expect scope.counter
          .toBe 1

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

      later done, ->
        expect scope.counter
          .toBe 1

  describe "$$postDigest", ->

    it "runs a $$postDigest function after each digest", ->

      scope.counter = 0

      # Post digest function is NOT passed the scope.
      scope.$$postDigest -> scope.counter++

      expect scope.counter
        .toBe 0

      expectCounterAfterDigest 1

      # $$postDigest functions are invoked once then discarded
      expectCounterAfterDigest 1

    it "does not include $$postDigest in the digest", ->

      scope.aValue = "original"

      scope.$$postDigest -> scope.aValue = "changed"

      scope.$watch watchAValue,
        (newValue, oldValue, s) -> s.watchedValue = newValue

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

  describe "isolated scopes", ->

    it "does not have access to the parent attributes when isolated", ->

      parent = new Scope()
      child = parent.$new true

      parent.aValue = "abc"

      expect child.aValue
        .toBe undefined

    it "cannot watchparent attributes when isolated", ->

      parent = new Scope()
      child = parent.$new true

      parent.aValue = "abc"

      child.$watch watchAValue, storeAValueWas

      child.$digest()

      expect child.aValueWas
        .toBe undefined

    it "digests its isolated children", -> 

      parent = new Scope()
      child = parent.$new true

      child.aValue = "abc"

      child.$watch watchAValue, storeAValueWas

      parent.$digest()

      expect child.aValueWas
        .toBe "abc"

    it "digests from root on $apply when isolated", ->

      parent = new Scope()
      child = parent.$new true
      child2 = child.$new()

      parent.aValue = "abc"
      parent.counter = 0

      parent.$watch watchAValue, incrementCounter

      child2.$apply ->

      expect parent.counter
        .toBe 1

    it "schedules a digest from root on $evalAsync when isolated", (done) ->

      parent = new Scope()
      child = parent.$new true
      child2 = child.$new()

      parent.aValue = "abc"
      parent.counter = 0

      parent.$watch watchAValue, incrementCounter

      child2.$evalAsync ->

      later done, ->
        expect parent.counter
          .toBe 1

    it "executes $evalAsync functions on isolated scopes", (done) ->

      parent = new Scope()
      child = parent.$new true

      child.$evalAsync (scope) -> scope.didEvalAsync = true

      later done, ->
        expect child.didEvalAsync
          .toBe true

    it "executes $$postDigest functions on isolated scopes", ->

      parent = new Scope()
      child = parent.$new true

      child.$$postDigest -> child.didPostDigest = true

      parent.$digest()

      expect child.didPostDigest
        .toBe true

  describe "$destroy", ->

    it "is no longer digested when $destroy has been invoked", ->

      parent = new Scope()
      child = parent.$new()

      child.aValue = [1, 2, 3]
      child.counter = 0

      child.$watch watchAValue, incrementCounter, true

      parent.$digest()

      expect child.counter
        .toBe 1

      child.aValue.push 4
      parent.$digest()

      expect child.counter
        .toBe 2


      child.$destroy()
      child.aValue.push 5

      parent.$digest()

      expect child.counter
        .toBe 2

  describe "$watchCollection", ->

    scope = null

    beforeEach -> scope = new Scope()

    watchArr = (s) -> s.arr
    watchObj = (s) -> s.obj

    it "works as $watch for a non-collection", ->

      newValueProvided = null
      oldValueProvided = null

      scope.aValue = 42
      scope.counter = 0

      scope.$watchCollection watchAValue, (newValue, oldValue, scope) ->

        newValueProvided = newValue
        oldValueProvided = oldValue
        scope.counter++

      expectCounterAfterDigest 1

      expect newValueProvided
        .toBe scope.aValue

      expect oldValueProvided
        .toBe scope.aValue

      scope.aValue = 43

      expectCounterAfterDigest 2

      expectCounterAfterDigest 2

    it "notices when the value becomes an array", ->

      scope.counter = 0

      scope.$watchCollection watchArr, incrementCounter

      expectCounterAfterDigest 1

      scope.arr = [1, 2, 3]

      expectCounterAfterDigest 2

      expectCounterAfterDigest 2

    it "notices when an item is added to an array", ->

      scope.arr = [1, 2, 3]
      scope.counter = 0

      scope.$watchCollection watchArr, incrementCounter

      expectCounterAfterDigest 1

      scope.arr.shift()

      expectCounterAfterDigest 2

      expectCounterAfterDigest 2

    it "notices when an item is removed from an array", ->

      scope.arr = [1, 2, 3]
      scope.counter = 0

      scope.$watchCollection watchArr, incrementCounter

      expectCounterAfterDigest 1

      scope.arr.shift()
      scope.$digest()

      expectCounterAfterDigest 2

      expectCounterAfterDigest 2

    it "notices an item replaced in an array", ->

      scope.arr = [1, 2, 3]
      scope.counter = 0

      scope.$watchCollection watchArr, incrementCounter

      expectCounterAfterDigest 1

      scope.arr[1] = 42

      expectCounterAfterDigest 2

      expectCounterAfterDigest 2

    it "does not fail on NaNs in arrays", ->

      scope.arr = [2, NaN, 3]
      scope.counter = 0

      scope.$watchCollection watchArr, incrementCounter

      expectCounterAfterDigest 1

    it "does not fail on NaN attributes in objects", ->

      scope.counter = 0
      scope.obj = {a: NaN}

      scope.$watchCollection watchObj, incrementCounter

      expectCounterAfterDigest 1

    it "notices items reordered in an array", ->

      scope.arr = [2, 1, 3]
      scope.counter =0

      scope.$watchCollection watchArr, incrementCounter

      expectCounterAfterDigest 1

      scope.arr.sort()

      expectCounterAfterDigest 2

      expectCounterAfterDigest 2

    it "notices an item replaced in an arguments object", ->

      (-> scope.arrayLike = arguments) 1, 2, 3
        
      scope.counter = 0

      scope.$watchCollection ((s) -> s.arrayLike), incrementCounter

      expectCounterAfterDigest 1

      scope.arrayLike[1] = 42

      expectCounterAfterDigest 2

      expectCounterAfterDigest 2

    it "notices when the value becomes an object", ->

      scope.counter = 0

      scope.$watchCollection watchObj, incrementCounter

      expectCounterAfterDigest 1

      scope.obj = {a: 1}

      expectCounterAfterDigest 2

      expectCounterAfterDigest 2

    it "notices when the an attribute is added to an object", ->

      scope.counter = 0
      scope.obj = {a: 1}

      scope.$watchCollection watchObj, incrementCounter

      expectCounterAfterDigest 1

      scope.obj.b = 2

      expectCounterAfterDigest 2

      expectCounterAfterDigest 2

    it "notices when an attribute is changed in an object", ->

      scope.counter = 0
      scope.obj = {a: 1}

      scope.$watchCollection watchObj, incrementCounter

      expectCounterAfterDigest 1

      scope.obj.a = 2

      expectCounterAfterDigest 2

      expectCounterAfterDigest 2

    it "notices when an attribute is removed from an object", ->

      scope.counter = 0
      scope.obj = {a: 1}

      scope.$watchCollection watchObj, incrementCounter

      expectCounterAfterDigest 1

      delete scope.obj.a

      expectCounterAfterDigest 2

      expectCounterAfterDigest 2

    it "does not consider any object with a length property as an array", ->

      scope.obj = {length: 42, otherKey: "abc"}      
      scope.counter = 0

      scope.$watchCollection watchObj, incrementCounter

      scope.$digest()

      scope.obj.newKey = "def"

      expectCounterAfterDigest 2

    it "gives the old non-collection value to listeners", ->

      oldValueGiven = null

      scope.aValue = 42

      scope.$watchCollection watchAValue, (n, o, s) -> oldValueGiven = o

      scope.$digest()

      scope.aValue = 32
      scope.$digest()

      expect oldValueGiven
        .toBe 42

    it "gives the old array value to listeners", ->

      oldValueGiven = null

      scope.aValue = [1, 2, 3]

      scope.$watchCollection watchAValue, (n, o, s) -> oldValueGiven = o

      scope.$digest()

      scope.aValue.push 4

      scope.$digest()

      expect oldValueGiven
        .toEqual [1, 2, 3]

    it "gives the old object value to listeners", ->

      oldValueGiven = null

      scope.aValue = {a: 1, b: 2}

      scope.$watchCollection watchAValue, (n, o, s) -> oldValueGiven = o

      scope.$digest()

      scope.aValue.c = 3

      scope.$digest()

      expect oldValueGiven
        .toEqual {a: 1, b: 2}

  describe "Events", ->

    parent = null
    scope = null
    child = null
    isolatedChild = null

    beforeEach ->
      parent = new Scope()
      scope = parent.$new()
      child = scope.$new()
      isolatedChild = scope.$new true

    it "allow registering listeners", ->

      listener1 = ->
      listener2 = ->
      listener3 = ->

      scope.$on "someEvent", listener1
      scope.$on "someEvent", listener2
      scope.$on "someOtherEvent", listener3

      expect scope.$$listeners
        .toEqual
          someEvent: [listener1, listener2]
          someOtherEvent: [listener3]

    it "registers different listners for every scope", ->

      listener1 = ->
      listener2 = ->
      listener3 = ->

      scope.$on "someEvent", listener1
      child.$on "someEvent", listener2
      isolatedChild.$on "someEvent", listener3

      expect scope.$$listeners
        .toEqual
          someEvent: [listener1]

      expect child.$$listeners
        .toEqual
          someEvent: [listener2]

      expect isolatedChild.$$listeners
        .toEqual
          someEvent: [listener3]

    for method in ["$emit", "$broadcast"]

      it "calls the listeners of the matching event on #{method}", ->
        listener1 = jasmine.createSpy()
        listener2 = jasmine.createSpy()

        scope.$on "someEvent", listener1
        scope.$on "someOtherEvent", listener2

        scope[method] "someEvent"

        expect listener1
          .toHaveBeenCalled()

        expect listener2
          .not.toHaveBeenCalled()

      it "passes an event object with a name to listeners on #{method}", ->

        listener = jasmine.createSpy()
        scope.$on "someEvent", listener

        scope[method] "someEvent"

        expect listener
          .toHaveBeenCalled()

        expect listener.calls.mostRecent().args[0].name
          .toEqual "someEvent"

      it "passes the same event object to each listener on #{method}", ->

        listener1 = jasmine.createSpy()
        listener2 = jasmine.createSpy()

        scope.$on "someEvent", listener1
        scope.$on "someEvent", listener2

        scope[method] "someEvent"

        expect listener1.calls.mostRecent().args[0]
          .toBe listener2.calls.mostRecent().args[0]

      it "passes additional arguments to listeners on #{method}", ->

        listener = jasmine.createSpy()
        scope.$on "someEvent", listener

        scope[method] "someEvent", "and", ["additional", "arguments"], "..."

        actual = listener.calls.mostRecent().args

        expect actual[1]
          .toEqual "and"

        expect actual[2]
          .toEqual ["additional", "arguments"]

        expect actual[3]
          .toEqual "..."

      it "returns the event object on #{method}", ->

        returnedEvent = scope[method] "someEvent"

        expect returnedEvent
          .toBeDefined()

        expect returnedEvent.name
          .toEqual "someEvent"







