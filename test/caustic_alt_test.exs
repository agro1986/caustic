defmodule Caustic.AltTest do
  use ExUnit.Case
  use ExUnitProperties
  
  doctest Caustic.Alt

  alias Caustic.Alt
  alias Caustic.Utils

  property "alternative pow is correct" do
    check all n <- integer() do
      check all e <- integer() do
        if n == 0 and e <= 0 do
          assert_raise ArithmeticError, fn -> Alt.pow(n, e) end
        else
          assert Alt.pow(n, e) == Utils.pow(n, e)
        end
      end
    end
  end
end
