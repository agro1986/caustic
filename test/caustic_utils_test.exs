defmodule Caustic.UtilsTest do
  use ExUnit.Case
  alias Caustic.Utils
  alias Caustic.Naive
  
  doctest Caustic.Utils
  
  @lorem_ipsum "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Lut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officiae deserunt mollit anim id est laborum."
  @lorem_ipsum_base64_no_newline "TG9yZW0gaXBzdW0gZG9sb3Igc2l0IGFtZXQsIGNvbnNlY3RldHVyIGFkaXBpc2NpbmcgZWxpdCwgc2VkIGRvIGVpdXNtb2QgdGVtcG9yIGluY2lkaWR1bnQgdXQgbGFib3JlIGV0IGRvbG9yZSBtYWduYSBhbGlxdWEuIEx1dCBlbmltIGFkIG1pbmltIHZlbmlhbSwgcXVpcyBub3N0cnVkIGV4ZXJjaXRhdGlvbiB1bGxhbWNvIGxhYm9yaXMgbmlzaSB1dCBhbGlxdWlwIGV4IGVhIGNvbW1vZG8gY29uc2VxdWF0LiBEdWlzIGF1dGUgaXJ1cmUgZG9sb3IgaW4gcmVwcmVoZW5kZXJpdCBpbiB2b2x1cHRhdGUgdmVsaXQgZXNzZSBjaWxsdW0gZG9sb3JlIGV1IGZ1Z2lhdCBudWxsYSBwYXJpYXR1ci4gRXhjZXB0ZXVyIHNpbnQgb2NjYWVjYXQgY3VwaWRhdGF0IG5vbiBwcm9pZGVudCwgc3VudCBpbiBjdWxwYSBxdWkgb2ZmaWNpYWUgZGVzZXJ1bnQgbW9sbGl0IGFuaW0gaWQgZXN0IGxhYm9ydW0u"

  @leviathan "Man is distinguished, not only by his reason, but by this singular passion from other animals, which is a lust of the mind, that by a perseverance of delight in the continued and indefatigable generation of knowledge, exceeds the short vehemence of any carnal pleasure."
  @leviathan_base64_no_newline "TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlzIHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLCB3aGljaCBpcyBhIGx1c3Qgb2YgdGhlIG1pbmQsIHRoYXQgYnkgYSBwZXJzZXZlcmFuY2Ugb2YgZGVsaWdodCBpbiB0aGUgY29udGludWVkIGFuZCBpbmRlZmF0aWdhYmxlIGdlbmVyYXRpb24gb2Yga25vd2xlZGdlLCBleGNlZWRzIHRoZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm5hbCBwbGVhc3VyZS4="
  
  test "base64 encoding" do
    assert Utils.base64_encode(@lorem_ipsum, new_line: false) == @lorem_ipsum_base64_no_newline
    assert Utils.base64_encode(@leviathan, new_line: false) == @leviathan_base64_no_newline
  end

  test "primality testing" do
    primes = Utils.primes_first_500()
    last = primes |> List.last()
    primes_test = 1..last |> Enum.filter(&Utils.prime?/1)
    assert primes_test == primes
  end

  test "primality testing using sieve of Eratosthenes" do
    primes = Utils.primes_first_500()
    last = primes |> List.last()
    primes_test = 1..last |> Enum.filter(&Utils.prime?/1)
    assert primes_test == primes
  end

  test "sum of two squares" do
    assert Utils.to_sum_of_two_squares(1) == nil
    assert Utils.to_sum_of_two_squares(2) == {1, 1}
    assert Utils.to_sum_of_two_squares(3) == nil
    assert Utils.to_sum_of_two_squares(5) == {1, 2}
    assert Utils.to_sum_of_two_squares(17) == {1, 4}
    assert Utils.to_sum_of_two_squares(12349) == {30, 107}
  end
  
  test "Euler's totient function" do
    1..4000
    |> Enum.each(fn n ->
      assert Utils.totient(n) == Naive.totient(n)
    end)
  end
  
  test "positive divisor count" do
    1..5000
    |> Enum.each(fn n ->
      assert Utils.positive_divisors_count(n) == Naive.positive_divisors_count(n)
    end)
  end

  test "positive divisor sum" do
    1..5000
    |> Enum.each(fn n ->
      assert Utils.positive_divisors_sum(n) == Naive.positive_divisors_sum(n)
    end)
  end
end

defmodule Caustic.Naive do
  alias Caustic.Utils
  
  def totient(m) when is_integer(m) and m > 0 do
    0..(m - 1) |> Enum.filter(&(Utils.gcd(m, &1) == 1)) |> Enum.count()
  end

  def positive_divisors_count(n), do: length(Utils.positive_divisors(n))

  def positive_divisors_sum(n), do: Enum.reduce(Utils.positive_divisors(n), 0, &+/2)
end