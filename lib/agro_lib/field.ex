defprotocol Caustic.Field do
  @fallback_to_any true
  
  @moduledoc """
  Protocol on field operations. Mainly to support `Caustic.FiniteField`.
  """

  @doc """
  ## Examples
  
      iex> Caustic.Field.add({7, 13}, {12, 13})
      {6, 13}
  """
  def add(x, y)

  @doc """
  ## Examples
  
      iex> Caustic.Field.sub({7, 13}, {12, 13})
      {8, 13}
  """
  def sub(x, y)

  @doc """
  ## Examples
  
      iex> Caustic.Field.mul({5, 19}, {3, 19})
      {15, 19}
      iex> Caustic.Field.mul({8, 19}, {17, 19})
      {3, 19}
  """
  def mul(x, y)
  
  @doc """
  ## Examples
  
      iex> Caustic.Field.div({2, 5}, {4, 5})
      {3, 5}
      iex> Caustic.Field.div({1, 5}, {2, 5})
      {3, 5}
  """
  def div(x, y)

  @doc """
  ## Examples
  
      iex> Caustic.Field.eq?({7, 13}, {7, 13})
      true
      iex> Caustic.Field.eq?({7, 13}, {6, 13})
      false
      iex> Caustic.Field.eq?({7, 13}, {7, 11})
      false
  """
  def eq?(x, y)

  @doc """
  ## Examples
  
      iex> Caustic.Field.ne?({7, 13}, {7, 13})
      false
      iex> Caustic.Field.ne?({7, 13}, {6, 13})
      true
      iex> Caustic.Field.ne?({7, 13}, {7, 11})
      true
  """
  def ne?(x, y)

  @doc """
  ## Examples
  
      iex> Caustic.Field.pow({7, 19}, {3, 19})
      {1, 19}
    
      iex> Caustic.Field.pow({9, 19}, {12, 19})
      {7, 19}
  """
  def pow(x, y)

  def neg(x)

  @doc """
  ## Examples
  
      iex> Caustic.Field.inverse({1, 71})
      {1, 71}
      iex> Caustic.Field.inverse({51, 71})
      {39, 71}
      iex> Caustic.Field.inverse({39, 71})
      {51, 71}
      iex> Caustic.Field.mul({51, 71}, {39, 71})
      {1, 71}
      iex> Caustic.Field.inverse({0, 71})
      nil
  """
  def inverse(x)
  
  @doc """
  Check if it is the additive identity.
  
  ## Examples
  
      iex> Caustic.Field.zero?(0)
      true
      iex> Caustic.Field.zero?(0.0)
      true
      iex> Caustic.Field.zero?({0, 5})
      true
  """
  def zero?(x)

  def sqrt(x)
end

defimpl Caustic.Field, for: Any do
  def add(x, y), do: x + y
  def sub(x, y), do: x - y
  def mul(x, y), do: x * y
  def div(x, y), do: x / y
  def eq?(x, y), do: x == y
  def ne?(x, y), do: x != y
  def pow(x, y), do: :math.pow(x, y)
  def neg(x), do: -x
  def inverse(x), do: 1 / x
  def zero?(x), do: x == 0
  def sqrt(x) do
    if x < 0, do: nil, else: :math.sqrt(x)
  end
end
