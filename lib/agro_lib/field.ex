defmodule Caustic.Field do
  @moduledoc """
  Methods for creation and manipulation of finite field element.
  
  ## Examples
  
      # Represents 1 which is a member of finite field of order 5
      iex> Caustic.Field.make(1, 5)
      {1, 5}
    
      # Modulo addition 1 + 4 mod 5
      iex> Caustic.Field.add({1, 5}, {4, 5})
      {0, 5}
    
      # Test for congruence 4 * 4 ≡ 1 (mod 5)
      iex> Caustic.Field.mul({4, 5}, {4, 5}) |> Caustic.Field.eq?({1, 5})
      true
  """
  
  alias Caustic.Utils
  import Caustic.Utils, only: [mod: 2]
  
  def make(num, prime) when is_integer(num) and is_integer(prime) and 0 <= num and num < prime, do: {num, prime}
  def to_string({num, prime}), do: "FieldElement_#{prime}(#{num})"
  
  @doc """
  ## Examples
  
      iex> Caustic.Field.eq?({7, 13}, {7, 13})
      true
      iex> Caustic.Field.eq?({7, 13}, {6, 13})
      false
      iex> Caustic.Field.eq?({7, 13}, {7, 11})
      false
  """
  def eq?({num1, prime1}, {num1, prime1}), do: true
  def eq?({_num1, _prime1}, {_num2, _prime2}), do: false

  @doc """
  ## Examples
  
      iex> Caustic.Field.ne?({7, 13}, {7, 13})
      false
      iex> Caustic.Field.ne?({7, 13}, {6, 13})
      true
      iex> Caustic.Field.ne?({7, 13}, {7, 11})
      true
  """
  def ne?(elem1, elem2), do: not eq?(elem1, elem2)
  
  @doc """
  ## Examples
  
      iex> Caustic.Field.add({7, 13}, {12, 13})
      {6, 13}
  """
  def add({x, prime}, {y, prime}), do: {mod(x + y, prime), prime}

  @doc """
  ## Examples
  
      iex> Caustic.Field.sub({7, 13}, {12, 13})
      {8, 13}
  """
  def sub({x, prime}, {y, prime}), do: {mod(x - y, prime), prime}
  
  @doc """
  ## Examples
  
      iex> Caustic.Field.mul({5, 19}, {3, 19})
      {15, 19}
    
      iex> Caustic.Field.mul({8, 19}, {17, 19})
      {3, 19}
  """
  def mul({x, prime}, {y, prime}), do: {mod(x * y, prime), prime}

  @doc """
  ## Examples
  
      iex> Caustic.Field.pow({7, 19}, {3, 19})
      {1, 19}
    
      iex> Caustic.Field.pow({9, 19}, {12, 19})
      {7, 19}
  """
  def pow({x, prime}, {y, prime}), do: {mod(Utils.pow(x, y), prime), prime}

end
