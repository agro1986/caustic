defmodule Caustic.Alt do
  @moduledoc """
  Alternative implementation of functions in Caustic.Utils.
  """

  alias Caustic.Utils

  def pow(n, p) when is_integer(p) and p >= 0 do
    # first find the exponents in base 2
    # e.g., 25 = 2^0 + 2^3 + 2^4
    # so to calculate 3^25 we calculate
    #   3^(2^0) . 3^(2^3) . 3^(2^4)
    # = 3 . (3^2)^(2^2) . (3^2)^(2^3)
    # = 3 . (9^2)^2 . (9^2)^(2^2)
    # = 3 . 81^2 . (81^2)^2
    # = 3 . 6561 . 6561^2
    # = 3 . 6561 . 43046721
    # note that the factor with exponent 2^4 can use result from the factor before it (6561)

    exps = Utils.binary_exponents p
    if length(exps) == 0 do
      if n == 0 do
        raise ArithmeticError, "Division by zero"
      else
        1
      end
    else
      cur_exp = 0
      cur_factor = n
      acc = 1
      _pow exps, cur_exp, cur_factor, acc
    end
  end
  def pow(n, p), do: 1.0 / pow(n, -p)

  # short circuit
  # if we use [] as base case,
  # we will do one useless cur_factor * cur_factor
  defp _pow([cur_exp], cur_exp, cur_factor, acc) do
    acc * cur_factor
  end
  defp _pow([cur_exp | rest], cur_exp, cur_factor, acc) do
    _pow(rest, cur_exp + 1, cur_factor * cur_factor, acc * cur_factor)
  end
  defp _pow(exps, cur_exp, cur_factor, acc) do
    _pow(exps, cur_exp + 1, cur_factor * cur_factor, acc)
  end
end
