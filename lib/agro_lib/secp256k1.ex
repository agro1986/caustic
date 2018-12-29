defmodule Caustic.Secp256k1 do
  @moduledoc """
  Convenience functions for the elliptic curve secp256k1 used in Bitcoin.
  """

  alias Caustic.FiniteField
  alias Caustic.Field
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

  @doc """
  Create a point in the secp256k1 curve. If you supply it with x and y coordinates
  outside of the curve it will throw an error.
  """
  def make_point(x, y) when is_integer(x) and is_integer(y), do: make_point(make_field_elem(x), make_field_elem(y))
  def make_point(x, y), do: ECPoint.make(x, y, a(), b())

  def make_point_infinity(), do: ECPoint.infinity(a(), b())

  @doc """
  The order of the finite field used in secp256k1.
  """
  def p(), do: @p

  @doc """
  The number of possible private keys, because when you consider private keys e >= n
  it will just loop to the same public keys.
  """
  def n(), do: @n

  @doc """
  The largest possible private key. Equals to the constant n - 1.
  """
  def priv_key_max(), do: @priv_key_max

  @doc """
  The constant `a` in the elliptic curve equation `y^2 = x^3 + ax + b`.

  ## Examples
      iex> {a, _p} = Caustic.Secp256k1.a()
      iex> a
      0
  """
  @spec a() :: FiniteField.finite_field_elem()
  def a(), do: make_field_elem(@a)

  @doc """
  The constant `b` in the elliptic curve equation `y^2 = x^3 + ax + b`.

  ## Examples
      iex> {b, _p} = Caustic.Secp256k1.b()
      iex> b
      7
  """
  def b(), do: make_field_elem(@b)

  @doc """
  The x component of the generator point G.
  """
  def g_x(), do: make_field_elem(@g_x)

  @doc """
  The y component of the generator point G.
  """
  def g_y(), do: make_field_elem(@g_y)

  @doc """
  The generator point `G` used in public key calculation `P = eG`.

  ## Examples

      iex> g = Caustic.Secp256k1.g()
      iex> n = Caustic.Secp256k1.n()
      iex> Caustic.ECPoint.mul(n, g) == Caustic.Secp256k1.make_point_infinity()
      true
  """
  def g(), do: make_point(g_x(), g_y())

  @doc """
  Verifies whether a given ECDSA signature is correct.

  ## Examples

      iex> z = 0xbc62d4b80d9e36da29c16c5d4d9f11731f36052c72401a76c23c0fb5a9b74423
      iex> r = 0x37206a0610995c58074999cb9767b87af4c4978db68c06e8e6e81d282047a7c6
      iex> s = 0x8ca63759c1157ebeaec0d03cecca119fc9a75bf8e6d0fa65c841c8e2738cdaec
      iex> pubkey_x = 0x04519fac3d910ca7e7138f7013706f619fa8f033e6ec6e09370ea38cee6a7574
      iex> pubkey_y = 0x82b51eab8c27c66e26c858a079bcdf4f1ada34cec420cafc7eac1a42216fb6c4
      iex> pubkey = Caustic.Secp256k1.make_point(pubkey_x, pubkey_y)
      iex> Caustic.Secp256k1.ecdsa_verify?(pubkey, z, {r, s})
      true
  """
  def ecdsa_verify?(pubkey, _z = <<z::size(256)>>, sig), do: ecdsa_verify?(pubkey, z, sig)
  def ecdsa_verify?(pubkey, z, _sig = {r, s}) when is_integer(z) and is_integer(r) and is_integer(r),
    do: ecdsa_verify?(pubkey, FiniteField.make(z, @n), {FiniteField.make(r, @n), FiniteField.make(s, @n)})
  def ecdsa_verify?(pubkey, z, _sig = {r, s}) do
    s_inv = Field.inverse(s)
    {u, _} = Field.mul(z, s_inv)
    {v, _} = Field.mul(r, s_inv)
    {r_calc, _s_calc, _a, _b} = ECPoint.add(ECPoint.mul(u, g()), ECPoint.mul(v, pubkey))
    {r_1, _p} = r_calc
    {r_2, _n} = r

    r_1 == r_2
  end

  # format as 256-bit hex
  def to_string({num, _}) do
    padding = div(256, 4)
    Utils.to_string(num, 16, padding: padding)
  end

  def to_string({nil, nil, _, _}), do: "infinity"
  def to_string({{x, p}, {y, p}, _a, _b}), do: "(#{x}, #{y})"
end
