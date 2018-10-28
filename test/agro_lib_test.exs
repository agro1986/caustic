defmodule AgroLibTest do
  use ExUnit.Case
  doctest AgroLib

  test "greets the world" do
    assert AgroLib.hello() == :world
  end
end
