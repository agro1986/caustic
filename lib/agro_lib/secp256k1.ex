defmodule Caustic.Secp256k1 do
  @moduledoc false

  alias Caustic.FiniteField
  alias Caustic.ECPoint
  alias Caustic.Utils

  @p 115792089237316195423570985008687907853269984665640564039457584007908834671663
  @a 0
  @b 7
  @g_x 55066263022277343669578718895168534326250603453777594175500187360389116729240
  @g_y 32670510020758816978083085130507043184471273380659243275938904335757337482424
  @priv_key_max 115792089237316195423570985008687907852837564279074904382605163141518161494336
  @n 115792089237316195423570985008687907852837564279074904382605163141518161494337

  def make_field_elem(num), do: FiniteField.make(num, @p)

  def make_point(x, y) when is_integer(x) and is_integer(y), do: make_point(make_field_elem(x), make_field_elem(y))
  def make_point(x, y), do: ECPoint.make(x, y, a(), b())
  def make_point_infinity(), do: ECPoint.infinity(a(), b())

  def p(), do: @p
  def n(), do: @n
  def a(), do: make_field_elem(@a)
  def b(), do: make_field_elem(@b)
  def g_x(), do: make_field_elem(@g_x)
  def g_y(), do: make_field_elem(@g_y)
  def g(), do: make_point(g_x(), g_y())

  # format as 256-bit hex
  def to_string({num, _}) do
    padding = div(256, 4)
    Utils.to_string(num, 16, padding: padding)
  end

  def to_string({nil, nil, _, _}), do: "infinity"
  def to_string({{x, p}, {y, p}, _a, _b}), do: "(#{x}, #{y})"
end
