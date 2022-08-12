defmodule ExDuckTest do
  use ExUnit.Case
  doctest ExDuck

  test "greets the world" do
    assert ExDuck.hello() == :world
  end
end
