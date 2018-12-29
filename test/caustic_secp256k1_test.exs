defmodule Caustic.Secp256k1Test do
  use ExUnit.Case
  alias Caustic.Secp256k1
  alias Caustic.ECPoint

  doctest Secp256k1

  test "Private key order" do
    assert ECPoint.infinity(Secp256k1.a, Secp256k1.b) == ECPoint.mul(Secp256k1.n, Secp256k1.g)
  end
end