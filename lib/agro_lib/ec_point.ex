defmodule Caustic.ECPoint do
  @moduledoc """
  Represents an elliptic curve point y^2 = x^3 + ax + b
  """
  
  def make(x, y, a, b) when (x == nil and y == nil) or (y * y == x * x * x + a * x + b) do
    {x, y, a, b}
  end
  
  def eq?({x, y, a, b}, {x, y, a, b}), do: true
  def eq?({_, _, _, _}, {_, _, _, _}), do: false
  
  def ne?(p1, p2), do: not eq?(p1, p2)
  
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
  """
  def add(p, inf = {nil, nil, _a, _b}), do: add(inf, p)
  def add({nil, nil, a, b}, {x, y, a, b}), do: {x, y, a, b}
  def add({x, y1, a, b}, {x, y2, a, b}) when y1 == -y2, do: infinity(a, b)
  def add({x, y, a, b}, {x, y, a, b}) do
    s = (3 * x * x + a) / (2 * y)
    x3 = s * s - 2 * x
    y3 = s * (x - x3) - y
    {x3, y3, a, b}
  end
  def add({x1, y1, a, b}, {x2, y2, a, b}) do
    # https://github.com/jimmysong/programmingbitcoin/blob/master/ch02.asciidoc
    s = (y2 - y1) / (x2 - x1)
    x3 = s * s - x1 - x2
    y3 = s * (x1 - x3) - y1
    {x3, y3, a, b}
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
    y_2 = x * x * x + a * x + b
    case y_2 do
      n when n < 0 ->
        []
      0 ->
        [{x, 0, a, b}]
      _ -> # y_2 > 0
        y = :math.sqrt(y_2)
        [{x, y, a, b}, {x, -y, a, b}]
    end
  end
end
