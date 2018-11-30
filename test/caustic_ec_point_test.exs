defmodule Caustic.ECPointTest do
  use ExUnit.Case
  alias Caustic.ECPoint
  alias Caustic.Field

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
end
