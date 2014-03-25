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