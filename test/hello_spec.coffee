describe "Hello", ->
  it "says hello to receiver", ->
    expect sayHello "Jane"
      .toBe "Hello, Jane!"
