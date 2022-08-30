defmodule ExDuckTest do
  use ExUnit.Case
  doctest ExDuck

  test "dice roll" do
    result = ExDuck.answer!("roll 1d1")
    assert result == %{answer: "1", type: "dice roll"}

    markdown = ExDuck.to_markdown(result)
    assert markdown == "# Dice Roll\n\n1 = 1\n"
  end
end
