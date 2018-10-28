defmodule AgroLib.Utils do
  use Bitwise
  
  @moduledoc """
  A collection of useful methods.
  """
  
  def base64_encode(n) when is_integer(n) and 0 <= n and n <= 25 do
    ascii = ?A + n
    << ascii >>
  end

  def base64_encode(n) when is_integer(n) and 26 <= n and n <= 51 do
    ascii = ?a + n - 26
    << ascii >>
  end

  def base64_encode(n) when is_integer(n) and 52 <= n and n <= 61 do
    ascii = ?0 + n - 52
    << ascii >>
  end

  def base64_encode(n) when n === 62, do: "+"
  def base64_encode(n) when n === 63, do: "/"

  @doc """
  Encodes a string into its base64 representation.
  Note that it uses MIME variant of encoding characters.
  However there are some stuffs not yet implemented from the standard,
  such as discarding non-encoding characters and adding newlines to
  the encoded string.
  https://en.wikipedia.org/wiki/Base64 (see Variants summary table)
  """
  def base64_encode(data) when is_binary(data), do: base64_encode(data, [])

  defp base64_encode(<<>>, acc), do: Enum.reverse(acc) |> Enum.join()

  # Got 3 bytes
  defp base64_encode(<<c1 :: size(6), c2 :: size(6), c3 :: size(6), c4 :: size(6), rest :: binary>>, acc) do
    acc = [base64_encode(c4), base64_encode(c3), base64_encode(c2), base64_encode(c1) | acc]
    base64_encode(rest, acc)
  end

  # The last block is 2 bytes
  defp base64_encode(<<c1 :: size(6), c2 :: size(6), c3 :: size(4)>>, acc) do
    c3 = c3 <<< 2
    acc = ["=", base64_encode(c3), base64_encode(c2), base64_encode(c1) | acc]
    base64_encode(<<>>, acc)
  end

  # The last block is 1 byte
  defp base64_encode(<<c1 :: size(6), c2 :: size(2)>>, acc) do
    c2 = c2 <<< 4
    acc = ["=", "=", base64_encode(c2), base64_encode(c1) | acc]
    base64_encode(<<>>, acc)
  end
  
  def base64_decode(str) do
    nil
  end
  
  @doc """
  Converts a bitstring (including binary) into array of 0s and 1s.
  
  ## Example
  
    iex> AgroLib.Utils.bitstring_to_array "Hey"
    [0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 1]
    
    iex> AgroLib.Utils.bitstring_to_array << 1 :: size(1), 0 :: size(1), 1 :: size(1) >>
    [1, 0, 1]
  """
  def bitstring_to_array(data) when is_bitstring(data), do: bitstring_to_array(data, [])
  
  defp bitstring_to_array(<<>>, acc), do: Enum.reverse(acc)
  
  defp bitstring_to_array(<< n :: size(1), rest :: bitstring >>, acc) do
    bitstring_to_array(rest, [n | acc])
  end
end
