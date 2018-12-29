defmodule Caustic.FiniteField do
  @moduledoc """
  Module for the creation of finite field element. For the supported operations,
  see `Caustic.Field`.
  
  ## Examples
  
      # Represents 1 which is a member of finite field of order 5
      iex> Caustic.FiniteField.make(1, 5)
      {1, 5}
    
      # Modulo addition 1 + 4 mod 5
      iex> Caustic.Field.add({1, 5}, {4, 5})
      {0, 5}
    
      # Test for congruence 4 * 4 ≡ 1 (mod 5)
      iex> Caustic.Field.mul({4, 5}, {4, 5}) |> Caustic.Field.eq?({1, 5})
      true
  """

  @type finite_field_elem() :: {integer(), integer()}

  @spec make(integer(), integer()) :: finite_field_elem()
  def make(num, prime) when is_integer(num) and is_integer(prime) and 0 <= num and num < prime, do: {num, prime}
  
  def to_string({num, prime}), do: "FieldElement_#{prime}(#{num})"
end

defimpl Caustic.Field, for: Tuple do
  alias Caustic.Utils
  import Caustic.Utils, only: [mod: 2]
  
  def add({x, prime}, {y, prime}), do: {mod(x + y, prime), prime}
  
  def sub({x, prime}, {y, prime}), do: {mod(x - y, prime), prime}
  
  def mul({x, prime}, {y, prime}), do: {mod(x * y, prime), prime}
  def mul({x, prime}, y), do: mul({x, prime}, {mod(y, prime), prime})

  def div(a = {_x, prime}, b = {_y, prime}), do: mul(a, inverse(b))
  
  def eq?({num1, prime1}, {num1, prime1}), do: true
  def eq?({_num1, _prime1}, {_num2, _prime2}), do: false
  
  def ne?(elem1, elem2), do: not eq?(elem1, elem2)
  
  def pow({x, prime}, {y, prime}), do: {Utils.pow_mod(x, y, prime), prime}
  def pow({x, prime}, y), do: {Utils.pow_mod(x, y, prime), prime}

  def neg({x, prime}), do: sub({0, prime}, {x, prime})
  
  def inverse({x, prime}) do
    result = Utils.mod_inverse(x, prime)
    if result === nil, do: nil, else: {result, prime}
  end
  
  def zero?(a = {_x, prime}), do: eq?(a, {0, prime})

  def sqrt({x, prime}) do
    _sqrt(0, x, prime)
  end

  defp _sqrt(prime, _, prime), do: nil
  defp _sqrt(root, x, prime) when rem(root * root, prime) == x, do: {root, prime}
  defp _sqrt(root, x, prime), do: _sqrt(root + 1, x, prime)
end