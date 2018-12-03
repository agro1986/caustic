defmodule Caustic.ECPointTest do
  use ExUnit.Case
  alias Caustic.ECPoint
  alias Caustic.Field
  alias Caustic.FiniteField
  alias Caustic.Utils

  doctest ECPoint

  test "invalidPoints" do
    p = 223
    a = {0, p}
    b = {7, p}
    invalid_points = [{200, 119}, {42, 99}]
    invalid_points |> Enum.each(fn {x, y} ->
      assert_raise RuntimeError, fn -> ECPoint.make({x, p}, {y, p}, a, b) end
    end)
  end

  test "secp256k1 sanity test" do
    p = Utils.pow(2, 256) - Utils.pow(2, 32) - 977
    a = FiniteField.make(0, p)
    b = FiniteField.make(7, p)
    g_x = FiniteField.make Utils.to_integer("0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"), p
    g_y = FiniteField.make Utils.to_integer("0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8"), p

    {g, is_point} = try do
      g = ECPoint.make(g_x, g_y, a, b)
      {g, true}
    rescue
      _ -> {nil, false}
    end

    assert is_point

    n = Utils.to_integer("0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141") # order of private key group
    assert ECPoint.mul(n, g) == ECPoint.infinity(a, b)
  end

  test "secp256k1 extreme values" do
    p = 115792089237316195423570985008687907853269984665640564039457584007908834671663

    a = {0, p}
    b = {7, p}

    g_x = {55066263022277343669578718895168534326250603453777594175500187360389116729240, p}
    g_y = {32670510020758816978083085130507043184471273380659243275938904335757337482424, p}
    g = ECPoint.make(g_x, g_y, a, b)

    priv_key_max = 115792089237316195423570985008687907852837564279074904382605163141518161494336

    assert {g_x, Field.neg(g_y), a, b} == ECPoint.mul(priv_key_max, g)
    assert ECPoint.infinity(a, b) == ECPoint.mul(priv_key_max + 1, g)
    assert g == ECPoint.mul(priv_key_max + 2, g)
  end

  test "correct addition" do
    g = {{15, 223}, {86, 223}, {0, 223}, {7, 223}}
    g3 = {{69, 223}, {137, 223}, {0, 223}, {7, 223}}
    g4 = {{69, 223}, {86, 223}, {0, 223}, {7, 223}}
    assert ECPoint.add(g, g3) == g4
  end
end
