defmodule Caustic.ECPoint do
  @moduledoc """
  Represents an elliptic curve point y^2 = x^3 + ax + b
  """
  
  alias Caustic.Field, as: F
  use Bitwise
  
  @doc """
  Create a point in an elliptic field.
  
  ## Examples
  
      iex> Caustic.ECPoint.make(-1, 1, 5, 7)
      {-1, 1, 5, 7}
      iex> Caustic.ECPoint.make(-1, -1, 5, 7)
      {-1, -1, 5, 7}
      iex> Caustic.ECPoint.make({17, 103}, {64, 103}, {0, 103}, {7, 103})
      {{17, 103}, {64, 103}, {0, 103}, {7, 103}}
      iex> Caustic.ECPoint.make({192, 223}, {105, 223}, {0, 223}, {7, 223})
      {{192, 223}, {105, 223}, {0, 223}, {7, 223}}
      iex> Caustic.ECPoint.make({17, 223}, {56, 223}, {0, 223}, {7, 223})
      {{17, 223}, {56, 223}, {0, 223}, {7, 223}}
  """
  def make(x, y, a, b) do
    if (x == nil and y == nil)
      or (F.eq?(F.mul(y, y), F.add(F.add(F.pow(x, 3), F.mul(a, x)), b))) do # y^2 == x^3 + ax + b
      {x, y, a, b}
    else
      raise "Not a point in an elliptic curve"
    end
  end
  
  @doc """
  Check whether two points in an elliptic field is equal.
  
  ## Examples
  
      iex> Caustic.ECPoint.eq?({-1, -1, 5, 7}, {-1, -1, 5, 7})
      true
  """
  def eq?({x, y, a, b}, {x, y, a, b}), do: true
  def eq?({_, _, _, _}, {_, _, _, _}), do: false

  @doc """
  Check whether two points in an elliptic field is not equal.
  
  ## Examples
  
      iex> Caustic.ECPoint.ne?({-1, 1, 5, 7}, {-1, -1, 5, 7})
      true
  """
  def ne?(p1, p2), do: not eq?(p1, p2)

  @doc """
  Create point of infinity in an elliptic curve y^2 = x^3 + ax + b.
  
  ## Examples
  
      iex> Caustic.ECPoint.infinity(5, 7)
      {nil, nil, 5, 7}
  """
  def infinity(a, b), do: make(nil, nil, a, b)

  @doc """
  Addition of points in an elliptic curve.
  
  ## Examples
  
      iex> Caustic.ECPoint.add(Caustic.ECPoint.make(-1, -1, 5, 7), Caustic.ECPoint.infinity(5, 7))
      {-1, -1, 5, 7}
      iex> Caustic.ECPoint.add(Caustic.ECPoint.infinity(5, 7), Caustic.ECPoint.make(-1, -1, 5, 7))
      {-1, -1, 5, 7}
      iex> Caustic.ECPoint.add(Caustic.ECPoint.make(-1, 1, 5, 7), Caustic.ECPoint.make(-1, -1, 5, 7))
      {nil, nil, 5, 7}

      iex> p = 223
      iex> a = {0, p}
      iex> b = {7, p}
      iex> x1 = {192, p}
      iex> y1 = {105, p}
      iex> x2 = {17, p}
      iex> y2 = {56, p}
      iex> p1 = Caustic.ECPoint.make(x1, y1, a, b)
      iex> p2 = Caustic.ECPoint.make(x2, y2, a, b)
      iex> Caustic.ECPoint.add(p1, p2)
      {{170, 223}, {142, 223}, {0, 223}, {7, 223}}

      iex> p = 223
      iex> a = {0, p}
      iex> b = {7, p}
      iex> x = {47, p}
      iex> y = {71, p}
      iex> p = Caustic.ECPoint.make(x, y, a, b)
      iex> Caustic.ECPoint.add(p, p)
      {{36, 223}, {111, 223}, {0, 223}, {7, 223}}

      iex> a = {0, 223}
      iex> b = {7, 223}
      iex> i = Caustic.ECPoint.infinity(a, b)
      iex> Caustic.ECPoint.add(i, i)
      {nil, nil, {0, 223}, {7, 223}}
  """
  def add({x, y, a, b}, {nil, nil, a, b}), do: {x, y, a, b}
  def add({nil, nil, a, b}, {x, y, a, b}), do: {x, y, a, b}
  def add({x, y, a, b}, {x, y, a, b}) do
    s = F.div(F.add(F.mul(F.mul(x, x), 3), a), F.mul(y, 2)) # (3 * x * x + a) / (2 * y)
    x3 = F.sub(F.mul(s, s), F.mul(x, 2)) # s * s - 2 * x
    y3 = F.sub(F.mul(s, F.sub(x, x3)), y) # s * (x - x3) - y
    {x3, y3, a, b}
  end
  def add({x1, y1, a, b}, {x2, y2, a, b}) do
    if F.eq?(x1, x2) and F.eq?(y1, F.neg(y2)) do
      infinity(a, b)
    else
      # https://github.com/jimmysong/programmingbitcoin/blob/master/ch02.asciidoc
      s = F.div(F.sub(y2, y1), F.sub(x2, x1)) # (y2 - y1) / (x2 - x1)
      x3 = F.sub(F.sub(F.mul(s, s), x1), x2) # s * s - x1 - x2
      y3 = F.sub(F.mul(s, F.sub(x1, x3)), y1) # s * (x1 - x3) - y1
      {x3, y3, a, b}
    end
  end

  @doc """
  ## Examples

      iex> p = 223
      iex> a = {0, p}
      iex> b = {7, p}
      iex> x = {47, p}
      iex> y = {71, p}
      iex> g = Caustic.ECPoint.make(x, y, a, b)
      iex> Caustic.ECPoint.mul(2, g)
      {{36, 223}, {111, 223}, {0, 223}, {7, 223}}

      iex> g = {{15, 223}, {86, 223}, {0, 223}, {7, 223}}
      iex> Caustic.ECPoint.mul(0, g)
      {nil, nil, {0, 223}, {7, 223}}
  """
  def mul(k, p = {_, _, a, b}) do
    inf = infinity(a, b)
    _mul(k, inf, p)
  end

  defp _mul(0, acc, _), do: acc
  defp _mul(k, acc, factor) do
    acc = if (k &&& 1) == 1, do: add(acc, factor), else: acc
    k = k >>> 1
    factor = add(factor, factor)
    _mul(k, acc, factor)
  end

  @doc """
  Find points on an elliptic curve.
  
  ## Examples
  
      iex> Caustic.ECPoint.find_points(-100, 5, 7)
      []
      iex> Caustic.ECPoint.find_points(-1.0, 5, 7)
      [{-1.0, 1.0, 5, 7}, {-1.0, -1.0, 5, 7}]
  """
  def find_points(x, a, b) do
    y_2 = F.add(F.add(F.mul(F.mul(x, x), x), F.mul(a, x)), b) # x * x * x + a * x + b

    if F.zero?(y_2) do
      [{x, y_2, a, b}]
    else
      # todo: find square root modulo
      case F.sqrt(y_2) do
        nil -> # y_2 < 0
          []
        y -> # y_2 > 0
          [{x, y, a, b}, {x, F.neg(y), a, b}]
      end
    end
  end
end
