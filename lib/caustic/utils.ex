defmodule Caustic.Utils do
  use Bitwise
  
  @base58_table "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  @base_prefixes %{2 => "0b", 16 => "0x"}
  @base58_version %{
    address: <<0x00>>, # base58 starts with 1
    address_p2sh: <<0x05>>, # base58 starts with 3
    address_testnet: <<0x6f>>, # base58 starts with m/n
    private_key_wif: <<0x80>>, # base58 starts with 5 for uncompressed and K/L for compressed
    private_key_bip38_encrypted: <<0x0142::size(16)>>, # base58 starts with 6P
    public_key_bit32_extended: <<0x0488b21e::size(32)>> # base58 starts with xpub
  }
  
  @moduledoc """
  A collection of useful methods.
  """
  
  @doc """
  Encodes an integer codepoint 0 <= `n` <= 63 to its MIME Base64 character.
  
  ## Examples
    
      iex> Caustic.Utils.base64_encode_char(0)
      "A"
      iex> Caustic.Utils.base64_encode_char(5)
      "F"
      iex> Caustic.Utils.base64_encode_char(26)
      "a"
      iex> Caustic.Utils.base64_encode_char(31)
      "f"
      iex> Caustic.Utils.base64_encode_char(52)
      "0"
      iex> Caustic.Utils.base64_encode_char(57)
      "5"
      iex> Caustic.Utils.base64_encode_char(62)
      "+"
      iex> Caustic.Utils.base64_encode_char(63)
      "/"
  """
  def base64_encode_char(n) when is_integer(n) and 0 <= n and n <= 25 do
    ascii = ?A + n
    << ascii >>
  end

  def base64_encode_char(n) when is_integer(n) and 26 <= n and n <= 51 do
    ascii = ?a + n - 26
    << ascii >>
  end

  def base64_encode_char(n) when is_integer(n) and 52 <= n and n <= 61 do
    ascii = ?0 + n - 52
    << ascii >>
  end

  def base64_encode_char(n) when n === 62, do: "+"
  def base64_encode_char(n) when n === 63, do: "/"

  @doc """
  Gets the character code of a MIME base64 digit.
  
  ## Examples
    
      iex> Caustic.Utils.base64_decode_char("A")
      0
      iex> Caustic.Utils.base64_decode_char("F")
      5
      iex> Caustic.Utils.base64_decode_char("a")
      26
      iex> Caustic.Utils.base64_decode_char("f")
      31
      iex> Caustic.Utils.base64_decode_char("0")
      52
      iex> Caustic.Utils.base64_decode_char("5")
      57
      iex> Caustic.Utils.base64_decode_char("+")
      62
      iex> Caustic.Utils.base64_decode_char("/")
      63
  """
  def base64_decode_char(<<char_code>>), do: _base64_decode_char(char_code)
  
  def _base64_decode_char(char_code) when is_integer(char_code) and ?A <= char_code and char_code <= ?Z do
    char_code - ?A
  end

  def _base64_decode_char(char_code) when is_integer(char_code) and ?a <= char_code and char_code <= ?z do
    26 + char_code - ?a
  end

  def _base64_decode_char(char_code) when is_integer(char_code) and ?0 <= char_code and char_code <= ?9 do
    52 + char_code - ?0
  end

  def _base64_decode_char(char_code) when char_code === ?+, do: 62
  def _base64_decode_char(char_code) when char_code === ?/, do: 63

  @doc """
  Encodes a string into its MIME Base64 representation.
  
  https://en.wikipedia.org/wiki/Base64 (see Variants summary table)
  
  ## Examples
  
      iex> Caustic.Utils.base64_encode("Man")
      "TWFu"
      iex> Caustic.Utils.base64_encode("Ma")
      "TWE="
      iex> Caustic.Utils.base64_encode("M")
      "TQ=="
      iex> Caustic.Utils.base64_encode("Man is distinguished, not only by his reason, but by this singular passion from other animals...")
      "TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlz\\r\\nIHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLi4u"
      iex> Caustic.Utils.base64_encode("Man is distinguished, not only by his reason, but by this singular passion from other animals...", new_line: false)
      "TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlzIHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLi4u"
  """
  def base64_encode(data, opts \\ []) when is_binary(data), do: _base64_encode(data, [], 0, Keyword.get(opts, :new_line, true))

  defp _base64_encode(<<>>, acc, _len, _new_line?), do: Enum.reverse(acc) |> Enum.join()

  # Got 3 bytes
  defp _base64_encode(<<c1 :: size(6), c2 :: size(6), c3 :: size(6), c4 :: size(6), rest :: binary>>, acc, len, new_line?) do
    {acc, len} = _base64_append_newline(acc, len, new_line?)
    acc = [base64_encode_char(c4), base64_encode_char(c3), base64_encode_char(c2), base64_encode_char(c1) | acc]
    _base64_encode(rest, acc, len + 4, new_line?)
  end

  # The last block is 2 bytes
  defp _base64_encode(<<c1 :: size(6), c2 :: size(6), c3 :: size(4)>>, acc, len, new_line?) do
    {acc, len} = _base64_append_newline(acc, len, new_line?)
    c3 = c3 <<< 2
    acc = ["=", base64_encode_char(c3), base64_encode_char(c2), base64_encode_char(c1) | acc]
    _base64_encode(<<>>, acc, len + 4, new_line?)
  end

  # The last block is 1 byte
  defp _base64_encode(<<c1 :: size(6), c2 :: size(2)>>, acc, len, new_line?) do
    {acc, len} = _base64_append_newline(acc, len, new_line?)
    c2 = c2 <<< 4
    acc = ["=", "=", base64_encode_char(c2), base64_encode_char(c1) | acc]
    _base64_encode(<<>>, acc, len + 4, new_line?)
  end

  defp _base64_append_newline(acc, 76, true), do: {["\n", "\r" | acc], 0}
  defp _base64_append_newline(acc, 76, false), do: {acc, 0}
  defp _base64_append_newline(acc, len, _new_line), do: {acc, len}

  @doc """
  Decodes a MIME Base64 encoded string.
  
  https://en.wikipedia.org/wiki/Base64 (see Variants summary table)
  
  ## Examples
  
      iex> Caustic.Utils.base64_decode("TWFu")
      "Man"
      iex> Caustic.Utils.base64_decode("TWE=")
      "Ma"
      iex> Caustic.Utils.base64_decode("TQ==")
      "M"
      iex> Caustic.Utils.base64_decode("TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlz\\r\\nIHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLi4u")
      "Man is distinguished, not only by his reason, but by this singular passion from other animals..."
  """
  def base64_decode(str) do
    str_clean = _base64_decode_ignore_invalid_chars(str, [])
    _base64_decode(str_clean, [])
  end
  
  defp _base64_decode(<<>>, acc), do: Enum.reverse(acc) |> :binary.list_to_bin()

  defp _base64_decode(<<a, b, ?=, ?=, rest :: binary>>, acc) do
    a = _base64_decode_char(a)
    b = _base64_decode_char(b)
    <<x, _y, _z>> = <<a :: size(6), b :: size(6), 0 :: size(6), 0 :: size(6)>>
    _base64_decode(rest, [x | acc])
  end

  defp _base64_decode(<<a, b, c, ?=, rest :: binary>>, acc) do
    a = _base64_decode_char(a)
    b = _base64_decode_char(b)
    c = _base64_decode_char(c)
    <<x, y, _z>> = <<a :: size(6), b :: size(6), c :: size(6), 0 :: size(6)>>
    _base64_decode(rest, [y, x| acc])
  end
  
  defp _base64_decode(<<a, b, c, d, rest :: binary>>, acc) do
    a = _base64_decode_char(a)
    b = _base64_decode_char(b)
    c = _base64_decode_char(c)
    d = _base64_decode_char(d)
    <<x, y, z>> = <<a :: size(6), b :: size(6), c :: size(6), d :: size(6)>>
    _base64_decode(rest, [z, y, x | acc])
  end
  
  defp _base64_decode_ignore_invalid_chars(<<>>, acc), do: Enum.reverse(acc) |> Enum.join()
  defp _base64_decode_ignore_invalid_chars(<<c, rest :: binary>>, acc) 
    when (?A <= c
      and c <= ?Z)
    or (?a <= c
      and c <= ?z)
    or (?0 <= c
      and c <= ?9)
    or c == ?+
    or c == ?/
    or c == ?=,
  do: _base64_decode_ignore_invalid_chars(rest, [<<c>> | acc])
  defp _base64_decode_ignore_invalid_chars(<<_c, rest :: binary>>, acc), do: _base64_decode_ignore_invalid_chars(rest, acc)
  
  @doc """
  Converts a bitstring (including binary) into array of 0s and 1s.
  For simple binary you can also use :binary.decode_unsigned
  
  ## Examples
  
      iex> Caustic.Utils.bitstring_to_array "Hey"
      [0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 1]
      iex> Caustic.Utils.bitstring_to_array << 1 :: size(1), 0 :: size(1), 1 :: size(1) >>
      [1, 0, 1]
  """
  def bitstring_to_array(data) when is_bitstring(data), do: _bitstring_to_array(data, [])
  
  defp _bitstring_to_array(<<>>, acc), do: Enum.reverse(acc)
  
  defp _bitstring_to_array(<< n :: size(1), rest :: bitstring >>, acc) do
    _bitstring_to_array(rest, [n | acc])
  end
  
  @doc """
  Calculates integer exponentiation. Exponent can be negative.
  
  ## Examples
  
      iex> Caustic.Utils.pow(3, 9)
      19683
      iex> Caustic.Utils.pow(2, 8)
      256
      iex> Caustic.Utils.pow(2, 256)
      115792089237316195423570985008687907853269984665640564039457584007913129639936
      iex> Caustic.Utils.pow(2, -2)
      0.25
  """
  def pow(n, p) when is_integer(p) and p >= 0, do: _pow(n, p, 1)
  def pow(n, p), do: 1.0 / pow(n, -p)
  
  defp _pow(0, 0, _), do: raise "Division by zero"
  defp _pow(_n, 0, acc), do: acc
  defp _pow(n, p, acc) when rem(p, 2) == 0, do: _pow(n * n, div(p, 2), acc)
  defp _pow(n, p, acc), do: _pow(n, p - 1, n * acc)
  
  @doc """
  Interprets a bitstring (including binary) as an unsigned integer. You can use :binary.decode_unsigned/1
  if it's a normal binary.
  
  ## Examples
  
      iex> Caustic.Utils.bitstring_to_integer(<<255, 255>>)
      65535
  """
  def bitstring_to_integer(data) when is_bitstring(data) and data != "" do
    len = bit_size(data)
    <<n :: size(len)>> = data
    n
  end

  @doc """
  Encodes an integer into its base58 representation. If given a string, by default it will
  interpret the string as a hex.
  
  If given hex and it has leading zeros, then each byte of zeros will be encoded as 1.
  
  ## Examples
  
      iex> Caustic.Utils.base58_encode("801e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aeddc47e83ff")
      "5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn"
      iex> Caustic.Utils.base58_encode(<<57>>, convert_from_hex: false)
      "z"
      iex> Caustic.Utils.base58_encode(63716817338599314535577169638518475271320430400871647684951348108655027767484127754748927)
      "5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn"
      iex> Caustic.Utils.base58_encode("0x000001")
      "112"
  """
  def base58_encode(str, opts \\ [])
  def base58_encode(str, opts) when is_binary(str) do
    opts = opts ++ [convert_from_hex: true]
    {n, padding} = if opts[:convert_from_hex] do
      n = str |> to_integer(16)
      padding = str |> hex_remove_prefix() |> _hex_get_zero_padding()
      {n, padding}
    else
      n = str |> :binary.decode_unsigned()
      padding = _binary_get_zero_padding(str)
      {n, padding}
    end
    
    _base58_encode_with_padding(n, padding)
  end
  
  def base58_encode(n, _opts) when is_integer(n) and 0 <= n and n <= 57 do
    String.slice(@base58_table, n, 1)
  end
  
  def base58_encode(n, _opts) when is_integer(n) and n >= 0 do
    to_digits(n, 58) |> Enum.map_join(&base58_encode/1)
  end
  
  def _base58_encode_with_padding(n, padding) do
    prefix = String.duplicate("1", padding)
    prefix <> base58_encode(n)
  end

  def _hex_get_zero_padding(str, acc \\ 0)
  def _hex_get_zero_padding(<<?0, ?0, rest::binary>>, acc), do: _hex_get_zero_padding(rest, acc + 1)
  def _hex_get_zero_padding(str, acc) do
    if rem(String.length(str), 2) == 0, do: acc, else: 0
  end

  def _binary_get_zero_padding(data, acc \\ 0)
  def _binary_get_zero_padding(<<0x00, rest::binary>>, acc), do: _binary_get_zero_padding(rest, acc + 1)
  def _binary_get_zero_padding(_, acc), do: acc
  
  #def _hex_remove_prefix
  
  @doc """
  Same as base58_decode but outputs an integer instead of hex string.
  """
  def base58_to_integer(str) when is_binary(str), do: _base58_to_integer(str, 0)
  
  defp _base58_to_integer(<<>>, acc), do: acc
  defp _base58_to_integer(<<c, rest :: binary>>, acc) do
    c = << c >>
    value = string_index_of @base58_table, c
    _base58_to_integer(rest, acc * 58 + value)
  end
  
  @doc """
  Decode a base58-encoded string into its hexadecimal string representation.
  
  ## Examples
  
      iex> Caustic.Utils.base58_decode("5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn")
      "0x801e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aeddc47e83ff"
      iex> Caustic.Utils.base58_decode("5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn", prefix: false)
      "801e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aeddc47e83ff"
  """
  def base58_decode(str, opts \\ []), do: base58_to_integer(str) |> to_string(16, opts)
  
  @doc """
  Encodes a binary to its base58check representation.
  
  Possible values for version: `:address`, `:address_p2sh`, `:address_testnet`,
  `private_key_wif`, `private_key_bip38_encrypted`, `public_key_bit32_extended`
  
  Can also use custom binary version.
  
  ## Examples
  
      iex> Caustic.Utils.base58check_encode("0x1e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aedd", :private_key_wif)
      "5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn"
      iex> Caustic.Utils.base58check_encode(<<Caustic.Utils.to_integer("0x1e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aedd")::size(256)>>, :private_key_wif, convert_from_hex: false)
      "5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn"
      iex> Caustic.Utils.base58check_encode(<<Caustic.Utils.to_integer("0x1e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aedd")::size(256), 0x01>>, :private_key_wif, convert_from_hex: false)
      "KxFC1jmwwCoACiCAWZ3eXa96mBM6tb3TYzGmf6YwgdGWZgawvrtJ"
      iex> Caustic.Utils.base58check_encode(<<Caustic.Utils.to_integer("1E99423A4ED27608A15A2616A2B0E9E52CED330AC530EDCC32C8FFC6A526AEDD", 16)::size(256), 0x01>>, :private_key_wif, convert_from_hex: false)
      "KxFC1jmwwCoACiCAWZ3eXa96mBM6tb3TYzGmf6YwgdGWZgawvrtJ"
      iex> Caustic.Utils.base58check_encode("f5f2d624cfb5c3f66d06123d0829d1c9cebf770e", :address)
      "1PRTTaJesdNovgne6Ehcdu1fpEdX7913CK"
      iex> Caustic.Utils.base58check_encode("000000cb23faea20aa20f02a02955ffd1d785518", :address)
      "1111DVWAb9XQh88gakJRcK14e1i1onvAL" # private key is 5KjhZsxt61XSPunjrPm8XUEAH1YN6zXm6pqT5D1hZ9mLoEAqKTp
  """
  def base58check_encode(payload, version, opts \\ []) do
    opts = opts ++ [convert_from_hex: true]
    
    if opts[:convert_from_hex] do
      payload_i = to_integer(payload, 16)
      size = 4 * String.length(hex_remove_prefix(payload))
      payload_raw = <<payload_i::size(size)>>
      _base58check_encode(payload_raw, version)
    else
      _base58check_encode(payload, version)
    end
  end
  
  def _base58check_encode(payload, version) when is_atom(version), do: _base58check_encode(payload, Map.fetch!(@base58_version, version))
  
  def _base58check_encode(payload, version) when is_binary(payload) and is_binary(version) do
    payload_with_version = version <> payload
    checksum = base58_checksum(payload_with_version)
    final_payload = payload_with_version <> checksum
    final_payload |> base58_encode(convert_from_hex: false)
  end
  
  def base58_checksum(data) do
    <<checksum::size(32), _rest::binary>> = :crypto.hash(:sha256, :crypto.hash(:sha256, data))
    <<checksum::size(32)>>
  end
  
  def base58_version(data) do
    _base58_version(data, Map.keys(@base58_version))
  end
  
  defp _base58_version(data, []), do: {nil, data}
  defp _base58_version(data, [key | rest]) do
    prefix = @base58_version[key]
    prefix_length = byte_size(prefix)
    case data do
      <<^prefix::binary-size(prefix_length), payload::binary>>
        -> {key, payload}
      _
        -> _base58_version(data, rest)
    end
  end
  
  @doc """
  Returns checksum, payload, and version
  
  ## Examples
  
      iex> Caustic.Utils.base58check_decode "5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn"
      {:ok, <<196, 126, 131, 255>>, "1e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aedd", :private_key_wif}
      iex> Caustic.Utils.base58check_decode "1J7mdg5rbQyUHENYdx39WVWK7fsLpEoXZy"
      {:ok, <<55, 254, 252, 208>>, "bbc1e42a39d05a4cc61752d6963b7f69d09bb27b", :address}
  """
  def base58check_decode(str) do
    str_i = base58_to_integer(str)
    {exp, remainder} = log2i(str_i)
    bin_digit = exp + (if remainder == 0, do: 0, else: 1)
    bin_digit = bin_digit + rem(bin_digit, 8) # multiple of 1 byte
    data_bin_size = div(bin_digit - 32, 8)
    <<data_bin::binary-size(data_bin_size), checksum::binary>> = <<str_i::size(bin_digit)>>
    data_normalized = _base58check_data_normalize(data_bin)

    #<<data_int::size(data_bin_size), checksum::binary>> = <<str_i::size(bin_digit)>>
    #data_bin = <<data_int::size(data_bin_size)>>
    checksum_computed = base58_checksum(data_normalized)

    #IO.puts("Data is #{inspect(data_bin)}")
    #IO.puts("Checksum is #{inspect(checksum)}")
    
    if checksum_computed != checksum do
      {:error, "Checksum doesn't match. Computed #{inspect(checksum_computed)} vs actual #{inspect(checksum)}"}
    else
      {version, payload_bin} = base58_version(data_normalized)
      payload_hex = Base.encode16(payload_bin, case: :lower)
      #IO.puts("Version is #{inspect @base58_version[version]}")
      #IO.puts("Payload id #{inspect payload_bin}")
      
      # bx uses :binary.decode_unsigned(checksum, :little) to print checksum
      {:ok, checksum, payload_hex, version}
    end
  end
  
  # data of type :bitcoin_address has prefix 0x00 which is lost on encoding,
  # so we need to restore it.
  defp _base58check_data_normalize(data) do
    _base58check_data_normalize(data, Map.values(@base58_version))
  end

  defp _base58check_data_normalize(data, []) do
    # address size must be 20 bytes, so with version it is 21 bytes
    target_size = 21
    current_size = byte_size(data)
    diff = (target_size - current_size) * 8
    <<0x00::size(diff), data::binary>>
  end
                                            
  defp _base58check_data_normalize(data, [prefix | rest]) do
    len = byte_size(prefix)
    case data do
       <<^prefix::binary-size(len), _rest::binary>> -> data
       _ -> _base58check_data_normalize(data, rest)
    end
  end
  
  def log2i(n) when is_integer(n) and n >=1 do
    res = _log2i(n, 0)
    {res, rem(n, pow(2, res))}
  end
  defp _log2i(1, acc), do: acc
  defp _log2i(n, acc), do: _log2i(div(n, 2), acc + 1)
  
  @doc """
  Converts a Bitcoin 256-bit private key to the Wallet Import Format. Defaults to outputting compressed format.
  
  ## Examples
  
      iex> Caustic.Utils.bitcoin_private_key_to_wif("1e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aedd")
      "KxFC1jmwwCoACiCAWZ3eXa96mBM6tb3TYzGmf6YwgdGWZgawvrtJ"
      iex> Caustic.Utils.bitcoin_private_key_to_wif("1e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aedd", compressed: false)
      "5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn"
  """
  def bitcoin_private_key_to_wif(hex_str, opts \\ []) do
    opts = opts ++ [compressed: true]
    hex_str = if opts[:compressed], do: hex_str <> "01", else: hex_str
    base58check_encode(hex_str, :private_key_wif)
  end
  
  @doc """
  Finds the index of an ASCII character inside a string. Not unicode friendly!
  
  ## Examples
  
      iex> Caustic.Utils.string_index_of("Hello", "H")
      0
      iex> Caustic.Utils.string_index_of("Hello", "h")
      nil
      iex> Caustic.Utils.string_index_of("Hello", "l")
      2
  """
  def string_index_of(str, c), do: _string_index_of(str, c, 0)
  defp _string_index_of(<<>>, _c, _), do: nil
  defp _string_index_of(<<next, _rest :: binary>>, c, i) when << next >> == c, do: i
  defp _string_index_of(<<_next, rest :: binary>>, c, i), do: _string_index_of(rest, c, i + 1)

  @doc """
  Find the digits of a nonnegative integer `n` in a particular `base`.
  
  ## Examples
      iex> Caustic.Utils.to_digits(321, 10)
      [3, 2, 1]
      iex> Caustic.Utils.to_digits(5, 2)
      [1, 0, 1]
      iex> Caustic.Utils.to_digits(255, 16)
      [15, 15]
      iex> Caustic.Utils.to_digits(0, 8)
      [0]
  """
  def to_digits(n, base)
    when is_integer(n)
    and is_integer(base)
    and n >= 0
    and base >= 2 do
    _to_digits(n, base, [])
  end

  defp _to_digits(0, _base, []), do: [0]
  defp _to_digits(0, _base, acc), do: acc
  defp _to_digits(n, base, acc) do
    d = div(n, base)
    r = rem(n, base)
    _to_digits(d, base, [r | acc])
  end
  
#  @doc """
#  Convert a digit's integer representation to its string representation.
#  
#  ## Examples
#  
#    iex> Caustic.Utils.to_string(8, 10)
#    "8"
#    iex> Caustic.Utils.to_string(15, 16)
#    "f"
#  """
#  def to_string(n, base)
#    when is_integer(n)
#    and is_integer(base)
#    and n >= 0
#    and base >= 2
#    and n < base
#    and base <= 36
#    do
#    _to_string(n, base)
#  end
  
  @doc """
  Convert an integer into its string representation in any `base`.
  
  ## Examples
  
      iex> Caustic.Utils.to_string(255, 16)
      "0xff"
      iex> Caustic.Utils.to_string(255, 16, prefix: false)
      "ff"
      iex> Caustic.Utils.to_string(5, 2)
      "0b101"
  """
  def to_string(n, base, opts \\ []) do
    opts = opts ++ [prefix: true, padding: 0]
    str = to_digits(n, base) |> Enum.map_join(&_to_string(&1, base))

    str = String.pad_leading(str, opts[:padding], "0")
    
    prefix = if opts[:prefix], do: Map.get(@base_prefixes, base, ""), else: "" 
    prefix <> str
  end

  defp _to_string(n, _base) when n <= 9, do: to_string(n)
  defp _to_string(n, _base), do: <<?a + n - 10>>
  
  @doc """
  Parse a string which can be in any base to integer, autodetecting the base using the prefix.
  
  ## Examples
  
      iex> Caustic.Utils.to_integer("0xff")
      255
      iex> Caustic.Utils.to_integer("0b101")
      5
      iex> Caustic.Utils.to_integer("321")
      321
  """
  def to_integer(str) do
    base = get_base(String.downcase(str))
    to_integer(str, base)
  end

  @doc """
  Parse a string which can be in any base to integer, specifying the base.
  
  ## Examples
  
      iex> Caustic.Utils.to_integer("ff", 16)
      255
      iex> Caustic.Utils.to_integer("101", 2)
      5
      iex> Caustic.Utils.to_integer("755", 8)
      493
      iex> Caustic.Utils.to_integer("321", 10)
      321
  """
  def to_integer(str, base) do
    str = String.downcase(str)
    prefix = Map.get(@base_prefixes, base)
    if prefix == nil do
      _to_integer(str, base)
    else
      if String.starts_with?(str, prefix) do
        prefix_len = String.length(prefix)
        rest = String.slice(str, prefix_len..-1)
        _to_integer(rest, base)
      else
        _to_integer(str, base)
      end
    end
  end
  
  defp _to_integer(str, base) do
    _to_integer(str, base, 0)
  end
  
  defp _to_integer(<<>>, _base, acc), do: acc
  
  defp _to_integer(<<digit, rest :: binary>>, base, acc) do
    acc = acc * base + _digit_to_integer(digit, base)
    _to_integer(rest, base, acc)
  end
  
  defp _digit_to_integer(char_code, base) when ?0 <= char_code and char_code <= ?9 and char_code - ?0 < base, do: char_code - ?0
  defp _digit_to_integer(char_code, base) when ?a <= char_code and char_code <= ?z and 10 + char_code - ?a < base, do: 10 + char_code - ?a
  
  @doc """
  Guess the base of an integer string using its prefix. Defaults to 10, and doesn't check for validity of the digits.
  
  ## Examples
  
      iex> Caustic.Utils.get_base("0xabf")
      16
      iex> Caustic.Utils.get_base("0b101")
      2
      iex> Caustic.Utils.get_base("321")
      10
  """
  def get_base(str) do
    keys = Map.keys @base_prefixes
    _get_base(str, keys)
  end
  
  defp _get_base(str, [base | rest]) do
    prefix = @base_prefixes[base]
    if String.starts_with?(str, prefix),
      do: base,
      else: _get_base(str, rest)
  end
  
  defp _get_base(<<c, rest :: binary>>, []) when ?0 <= c and c <= ?9, do: _get_base(rest, [])
  defp _get_base("", []), do: 10
  
  @doc """
  Removes hexadecimal prefix from a string.
  
  ## Examples
  
      iex> Caustic.Utils.hex_remove_prefix("0xff")
      "ff"
      iex> Caustic.Utils.hex_remove_prefix("0XFF")
      "FF"
      iex> Caustic.Utils.hex_remove_prefix("ff")
      "ff"
  """
  def hex_remove_prefix(str) do
    if String.starts_with?(str, ["0x", "0X"]) do
      String.slice(str, 2..-1)
    else
      str
    end
  end

  @doc """
  Finds the least residue of a number modulo `m`.
  
  ## Examples
  
      iex> Caustic.Utils.mod(0, 3)
      0
      iex> Caustic.Utils.mod(-27, 13)
      12
      iex> Caustic.Utils.mod(-3, 3)
      0
  """
  def mod(x, m) when x >= 0, do: rem(x, m)
  def mod(x, m) when x < 0, do: rem(rem(x, m) + m, m)

  @doc """
  Fast exponentiation modulo m. Calculates x^y mod m.
  
  With x = 5, y = 12345, m = 17, and repeated 1000 times,
  it is faster by naive method by a factor of 150 on
  a particular benchmark machine.

  https://www.khanacademy.org/computing/computer-science/cryptography/modarithmetic/a/modular-exponentiation
  https://www.khanacademy.org/computing/computer-science/cryptography/modarithmetic/a/fast-modular-exponentiation
  
  ## Examples
  
      iex> Caustic.Utils.pow_mod(5, 0, 19)
      1
      iex> Caustic.Utils.pow_mod(5, 1, 19)
      5
      iex> Caustic.Utils.pow_mod(5, 117, 19)
      1
      iex> Caustic.Utils.pow_mod(7, 256, 13)
      9
      iex> Caustic.Utils.pow_mod(2, 90, 13)
      12
      iex> Caustic.Utils.pow_mod(50, -1, 71)
      27
      iex> Caustic.Utils.pow_mod(7, -3, 13)
      8
  """
  def pow_mod(x, -1, m), do: mod_inverse(x, m)
  def pow_mod(x, y, m) when y < -1 do
    inverse = pow_mod(x, -1, m)
    pow_mod(inverse, -y, m)
  end
  def pow_mod(x, y, m) do
    digits = to_digits(y, 2)
    
    digits
    |> Enum.reverse()
    |> Enum.reduce({1, mod(x, m)}, fn n, {acc, factor} ->
      acc = if n == 0, do: acc, else: acc * factor
      factor = factor * factor |> mod(m)
      {acc, factor}
    end)
    |> elem(0)
    |> mod(m)
  end
  
  @doc """
  Find the greatest common divisor of two integers.
  
  Proof: https://www.khanacademy.org/computing/computer-science/cryptography/modarithmetic/a/the-euclidean-algorithm
  
  ## Examples

      iex> Caustic.Utils.gcd(1, 0)
      1

      iex> Caustic.Utils.gcd(-1, 0)
      1
  
      iex> Caustic.Utils.gcd(270, 192)
      6

      iex> Caustic.Utils.gcd(-270, 192)
      6

      iex> Caustic.Utils.gcd(270, -192)
      6

      iex> Caustic.Utils.gcd(-270, -192)
      6
  """
  def gcd(a, b) when a < 0, do: gcd(-a, b)
  def gcd(a, b) when b < 0, do: gcd(a, -b)
  def gcd(a, b) when a != 0 or b != 0, do: _gcd(a, b)
  def _gcd(0, b), do: b
  def _gcd(a, 0), do: a
  def _gcd(a, b) do
    #q = div(a, b)
    r = mod(a, b)
    _gcd(b, r)
  end

  @doc """
  Find the greatest common divisor `d` of two integers `a` and `b`, while also finding
  the coefficients `x` and `y` such that `ax + by = d`.

  ## Examples
      iex> Caustic.Utils.gcd_with_coefficients(3, 0)
      {3, 1, 0}

      iex> Caustic.Utils.gcd_with_coefficients(6, 3)
      {3, 0, 1}

      iex> Caustic.Utils.gcd_with_coefficients(270, 192)
      {6, 5, -7}

      iex> Caustic.Utils.gcd_with_coefficients(-270, 192)
      {6, -5, -7}

      iex> Caustic.Utils.gcd_with_coefficients(270, -192)
      {6, 5, 7}

      iex> Caustic.Utils.gcd_with_coefficients(-270, -192)
      {6, -5, 7}

      iex> Caustic.Utils.gcd_with_coefficients(314, 159)
      {1, -40, 79}
  """
  def gcd_with_coefficients(a, b) when a < 0 do
    {d, x, y} = gcd_with_coefficients(-a, b)
    {d, -x, y}
  end

  def gcd_with_coefficients(a, b) when b < 0 do
    {d, x, y} = gcd_with_coefficients(a, -b)
    {d, x, -y}
  end

  def gcd_with_coefficients(a, b) when a < b do
    {d, x, y} = gcd_with_coefficients(b, a)
    {d, y, x}
  end

  def gcd_with_coefficients(a, b) when a != 0, do: _gcd_with_coefficients(a, b, 1, 0, 0, 1)

  def _gcd_with_coefficients(a, 0, x, y, _, _), do: {a, x, y}

  def _gcd_with_coefficients(a, b, x_prev_prev, y_prev_prev, x_prev, y_prev) do
    q = div(a, b)
    r = mod(a, b)
    x = x_prev_prev - q * x_prev
    y = y_prev_prev - q * y_prev
    _gcd_with_coefficients(b, r, x_prev, y_prev, x, y)
  end

  @doc """
  Find the modular inverse.
  
  Using Euclidean Algorithm: https://www.math.utah.edu/~fguevara/ACCESS2013/Euclid.pdf
  
  ## Examples
  
      iex> Caustic.Utils.mod_inverse(1, 101)
      1
      iex> Caustic.Utils.mod_inverse(2, 3)
      2
      iex> Caustic.Utils.mod_inverse(50, 71)
      27
      iex> Caustic.Utils.mod_inverse(25, 50)
      nil
      iex> Caustic.Utils.mod_inverse(8, 11)
      7
      iex> Caustic.Utils.mod_inverse(345, 76408)
      48281
      iex> Caustic.Utils.mod_inverse(71, 50)
      31
    
      # Bitcoin elliptic curve
      iex> Caustic.Utils.mod_inverse(345, 115792089237316195423570985008687907853269984665640564039457584007908834671663)
      53029420578249156164997726467746925915410601672960026429664632676085785153979
  """
  def mod_inverse(a, m) when a >= m or a < 0, do: mod_inverse(mod(a, m), m)
  def mod_inverse(a, m) do
    result = _mod_inverse(m, a)
    if result == nil, do: nil, else: mod(result, m) # normalize to 0 < inverse < m
  end

  # instead of using sentinel values q_prev = nil and q_prev_prev = nil
  # the equation works perfectly if we use initial values of q_prev = 1 and q_prev_prev = 0
  defp _mod_inverse(m, a, q_prev \\ 1, q_prev_prev \\ 0)
  
  # not coprimes, doesn't have inverse mod m
  defp _mod_inverse(_m, 0, _, _), do: nil
  
  defp _mod_inverse(_m, 1, q_prev, _), do: q_prev
  
  defp _mod_inverse(m, a, q_prev, q_prev_prev) do
    q = div(m, a)
    r = mod(m, a)

    #IO.puts("[#{m}] = [#{a}] . #{q} + #{r}")
    
    _mod_inverse(a, r, q_prev_prev - q * q_prev, q_prev)
  end

  # 1 is a unit
  def prime?(n) when n <= 1, do: false
  def prime?(n), do: _prime?(n, 2)

  # if a number n is composite, then it is divisible by a prime
  # less than or equal to sqrt(n)
  # TODO: Optimize using the first n primes
  defp _prime?(n, factor) when factor * factor > n, do: true
  defp _prime?(n, factor) when rem(n, factor) == 0, do: false
  defp _prime?(n, factor), do: _prime?(n, factor + 1)

  # 1 is a unit
  @doc """
  Checks whether an integer `n > 1` is a composite number. 1 is a unit,
  neither a prime nor composite. Will return false on `n <= 1`.

  ## Examples

      iex> Caustic.Utils.composite?(4)
      true
      iex> Caustic.Utils.composite?(2)
      false
      iex> Caustic.Utils.composite?(3)
      false
      iex> Caustic.Utils.composite?(1)
      false
  """
  def composite?(n) when n <= 1, do: false
  def composite?(n), do: not prime?(n)

  @doc """
  Find the prime factors of an integer.
  
  ## Examples

      iex> Caustic.Utils.factorize(72)
      [2, 2, 2, 3, 3]
      iex> Caustic.Utils.factorize(480)
      [2, 2, 2, 2, 2, 3, 5]
      iex> Caustic.Utils.factorize(357171293798123)
      [7, 181, 1459, 193216691]
      iex> Caustic.Utils.factorize(100000001)
      [17, 5882353]
      iex> Caustic.Utils.factorize(9223372036854775807) # largest 64-bit integer
      [7, 7, 73, 127, 337, 92737, 649657]
      iex> Caustic.Utils.factorize(18446744073709551615) # largest 64-bit unsigned integer
      [3, 5, 17, 257, 641, 65537, 6700417]
      iex> Caustic.Utils.factorize(18446744073709551615 * 3571 * 5901331)
      [3, 5, 17, 257, 641, 3571, 65537, 5901331, 6700417]
      iex> Caustic.Utils.factorize(1)
      []
  """
  def factorize(n) when n <= 1, do: []
  def factorize(n), do: _factorize(n, [])

  defp _factorize(1, factors), do: factors |> Enum.reverse()
  defp _factorize(n, factors) do
    p = smallest_prime_divisor(n)
    _factorize(div(n, p), [p | factors])
  end

#  defp _factorize(n, factors) do
#    sqrt = floor(:math.sqrt(n))
#    divisors = 2..sqrt |> Enum.filter(& rem(n, &1) == 0)
#    smallest_prime_divisor = divisors |> Enum.filter(&prime?/1) |> List.first()
#    smallest_prime_divisor = if smallest_prime_divisor === nil, do: n, else: smallest_prime_divisor
#    factors = [smallest_prime_divisor | factors]
#    _factorize(div(n, smallest_prime_divisor), factors)
#  end

  def smallest_prime_divisor(n) when n <= 1, do: nil
  def smallest_prime_divisor(n), do: _smallest_prime_divisor(n, 2)

  defp _smallest_prime_divisor(n, factor) when factor * factor > n, do: n
  defp _smallest_prime_divisor(n, factor) when rem(n, factor) == 0, do: factor
  defp _smallest_prime_divisor(n, factor), do: _smallest_prime_divisor(n, factor + 1)
#
#    if prime?(factor), do: factor, else: _smallest_prime_divisor(n, factor + 1)
#  end

  @doc """
  Checks whether an integer is a prime using Sieve of Eratosthenes algorithm.
  Don't use on very large numbers.
  """
  def prime_sieve?(n) when n <= 1, do: false
  def prime_sieve?(n) do
    sieve = List.duplicate(true, n + 1) |> List.to_tuple() # assume all are primes
    _prime_sieve?(n, 2, sieve)
  end

  defp _prime_sieve?(n, factor, sieve) when factor * factor > n, do: true
  defp _prime_sieve?(n, factor, sieve) do
    is_prime = elem(sieve, factor)
    if is_prime do
      {sieve, n_is_composite} = _sieve_sweep(sieve, factor * 2, factor)
      if n_is_composite, do: false, else: _prime_sieve?(n, factor + 1, sieve)
    else
      _prime_sieve?(n, factor + 1, sieve)
    end
  end

  defp _sieve_sweep(sieve, next, factor) when next == tuple_size(sieve) - 1, do: {sieve, true}
  defp _sieve_sweep(sieve, next, factor) when next >= tuple_size(sieve), do: {sieve, false}
  defp _sieve_sweep(sieve, next, factor) do
    sieve = put_elem(sieve, next, false)
    _sieve_sweep(sieve, next + factor, factor)
  end

  # {time, res} = :timer.tc(Utils, :prime_sieve_up_to, [10_000_000])
  # {time, :ok} = :timer.tc Utils, :write_to_file, [Enum.to_list(1..10_000_000), "/tmp/elixir_test_out_2.txt", 10] # 2 minutes
  @doc """
  Find all primes `p ≤ n` using Sieve of Eratosthenes method.
  
  ## Examples
      iex> Caustic.Utils.prime_sieve_up_to(10)
      [2, 3, 5, 7]

      iex> Caustic.Utils.prime_sieve_up_to(30)
      [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]

      iex> Caustic.Utils.prime_sieve_up_to(100)
      [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]
  """
  def prime_sieve_up_to(n) when n >= 2 do
#    easy_primes = [ 2,  3,  5,  7, 11,
#                   13, 17, 19, 23, 29]
    easy_primes = primes_first_500()
    first_sieves = 2..n |> Enum.filter(&_potentially_prime?(&1, easy_primes))
    check_limit = trunc(:math.sqrt(n))

    {left, right} = list_split first_sieves, Enum.count(easy_primes)
    left = left |> Enum.filter(& &1 <= n)
    if Enum.count(right) == 0 do
      left
    else
      _prime_sieve_up_to(check_limit, Enum.reverse(left), right)
    end
  end

  @doc """
  Splits a list into its first `n` elements and the rest.

  ## Examples

      iex> Caustic.Utils.list_split([1, 2, 3, 4, 5], 2)
      {[1, 2], [3, 4, 5]}

      iex> Caustic.Utils.list_split([1, 2, 3], 5)
      {[1, 2, 3], []}
  """
  def list_split(objs, n) when n >= 0, do: _list_split([], objs, n)

  defp _list_split(left, right, 0), do: {Enum.reverse(left), right}
  defp _list_split(left, [], _), do: _list_split(left, [], 0)
  defp _list_split(left, [o | rest], n), do: _list_split([o | left], rest, n - 1)

  defp _prime_sieve_up_to(check_limit, left, right = [p | _]) when p > check_limit do
    Enum.reverse(left) ++ right
  end
  defp _prime_sieve_up_to(check_limit, left, [p | rest]) do
    rest = rest |> Enum.filter(& rem(&1, p) != 0)
    _prime_sieve_up_to(check_limit, [p | left], rest)
  end

  defp _potentially_prime?(n, []), do: true
  defp _potentially_prime?(n, [d | rest]) do
    if d < n and rem(n, d) == 0 do
      false
    else
      _potentially_prime?(n, rest)
    end
  end

  def write_to_file(list, path, item_per_line) do
    {:ok, file} = File.open path, [:write] # or :append
    :ok = _write_to_file file, list, item_per_line, 0
    File.close file
  end

  defp _write_to_file(file, [], _, _), do: :ok
  defp _write_to_file(file, [item | rest], item_per_line, i) do
    IO.binwrite file, "#{item}"

    if rem(i, item_per_line) === item_per_line - 1 do
      IO.binwrite file, "\n"
    else
      IO.binwrite file, " "
    end

    _write_to_file file, rest, item_per_line, i + 1
  end

  def primes_first_500() do
    [
      2, 3, 5, 7, 11, 13, 17, 19, 23, 29,
      31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
      73, 79, 83, 89, 97, 101, 103, 107, 109, 113,
      127, 131, 137, 139, 149, 151, 157, 163, 167, 173,
      179, 181, 191, 193, 197, 199, 211, 223, 227, 229,
      233, 239, 241, 251, 257, 263, 269, 271, 277, 281,
      283, 293, 307, 311, 313, 317, 331, 337, 347, 349,
      353, 359, 367, 373, 379, 383, 389, 397, 401, 409,
      419, 421, 431, 433, 439, 443, 449, 457, 461, 463,
      467, 479, 487, 491, 499, 503, 509, 521, 523, 541,
      547, 557, 563, 569, 571, 577, 587, 593, 599, 601,
      607, 613, 617, 619, 631, 641, 643, 647, 653, 659,
      661, 673, 677, 683, 691, 701, 709, 719, 727, 733,
      739, 743, 751, 757, 761, 769, 773, 787, 797, 809,
      811, 821, 823, 827, 829, 839, 853, 857, 859, 863,
      877, 881, 883, 887, 907, 911, 919, 929, 937, 941,
      947, 953, 967, 971, 977, 983, 991, 997, 1009, 1013,
      1019, 1021, 1031, 1033, 1039, 1049, 1051, 1061, 1063, 1069,
      1087, 1091, 1093, 1097, 1103, 1109, 1117, 1123, 1129, 1151,
      1153, 1163, 1171, 1181, 1187, 1193, 1201, 1213, 1217, 1223,
      1229, 1231, 1237, 1249, 1259, 1277, 1279, 1283, 1289, 1291,
      1297, 1301, 1303, 1307, 1319, 1321, 1327, 1361, 1367, 1373,
      1381, 1399, 1409, 1423, 1427, 1429, 1433, 1439, 1447, 1451,
      1453, 1459, 1471, 1481, 1483, 1487, 1489, 1493, 1499, 1511,
      1523, 1531, 1543, 1549, 1553, 1559, 1567, 1571, 1579, 1583,
      1597, 1601, 1607, 1609, 1613, 1619, 1621, 1627, 1637, 1657,
      1663, 1667, 1669, 1693, 1697, 1699, 1709, 1721, 1723, 1733,
      1741, 1747, 1753, 1759, 1777, 1783, 1787, 1789, 1801, 1811,
      1823, 1831, 1847, 1861, 1867, 1871, 1873, 1877, 1879, 1889,
      1901, 1907, 1913, 1931, 1933, 1949, 1951, 1973, 1979, 1987,
      1993, 1997, 1999, 2003, 2011, 2017, 2027, 2029, 2039, 2053,
      2063, 2069, 2081, 2083, 2087, 2089, 2099, 2111, 2113, 2129,
      2131, 2137, 2141, 2143, 2153, 2161, 2179, 2203, 2207, 2213,
      2221, 2237, 2239, 2243, 2251, 2267, 2269, 2273, 2281, 2287,
      2293, 2297, 2309, 2311, 2333, 2339, 2341, 2347, 2351, 2357,
      2371, 2377, 2381, 2383, 2389, 2393, 2399, 2411, 2417, 2423,
      2437, 2441, 2447, 2459, 2467, 2473, 2477, 2503, 2521, 2531,
      2539, 2543, 2549, 2551, 2557, 2579, 2591, 2593, 2609, 2617,
      2621, 2633, 2647, 2657, 2659, 2663, 2671, 2677, 2683, 2687,
      2689, 2693, 2699, 2707, 2711, 2713, 2719, 2729, 2731, 2741,
      2749, 2753, 2767, 2777, 2789, 2791, 2797, 2801, 2803, 2819,
      2833, 2837, 2843, 2851, 2857, 2861, 2879, 2887, 2897, 2903,
      2909, 2917, 2927, 2939, 2953, 2957, 2963, 2969, 2971, 2999,
      3001, 3011, 3019, 3023, 3037, 3041, 3049, 3061, 3067, 3079,
      3083, 3089, 3109, 3119, 3121, 3137, 3163, 3167, 3169, 3181,
      3187, 3191, 3203, 3209, 3217, 3221, 3229, 3251, 3253, 3257,
      3259, 3271, 3299, 3301, 3307, 3313, 3319, 3323, 3329, 3331,
      3343, 3347, 3359, 3361, 3371, 3373, 3389, 3391, 3407, 3413,
      3433, 3449, 3457, 3461, 3463, 3467, 3469, 3491, 3499, 3511,
      3517, 3527, 3529, 3533, 3539, 3541, 3547, 3557, 3559, 3571
    ]
  end

  @doc """
  Calculate the document hash, used for ECDSA.
  """
  def hash256(str), do: :crypto.hash(:sha256, :crypto.hash(:sha256, str))

  @doc """
  Calculate the md5 hash.
  """
  def md5(str), do: :crypto.hash(:md5, str)

  @doc """
  If an integer can be written as the sum of the squares of two positive integers,
  return those two integers {a, b} where a <= b.

  ## Examples

      iex> Caustic.Utils.to_sum_of_two_squares(17)
      {1, 4}
      iex> Caustic.Utils.to_sum_of_two_squares(1)
      nil
  """
  def to_sum_of_two_squares(i) when is_integer(i) and i > 0 do
    sqrt = trunc(:math.sqrt(i))
    _to_sum_of_two_squares(i, 1, 1, sqrt)
  end

  def _to_sum_of_two_squares(i, a, b, _) when a * a + b * b == i, do: {a, b}
  def _to_sum_of_two_squares(i, a, b, sqrt) when b + 1 <= sqrt, do: _to_sum_of_two_squares(i, a, b + 1, sqrt)
  def _to_sum_of_two_squares(i, a, b, sqrt) when a + 1 <= sqrt, do: _to_sum_of_two_squares(i, a + 1, a + 1, sqrt)
  def _to_sum_of_two_squares(_, _, _, _), do: nil

  @doc """
  Checks whether `a` divides `b`.
  See https://math.stackexchange.com/questions/666103/why-would-some-elementary-number-theory-notes-exclude-00 and
  https://math.stackexchange.com/questions/2174535/does-zero-divide-zero

  ## Examples

      iex> Caustic.Utils.divides(2, 8)
      true
      iex> Caustic.Utils.divides(2, 3)
      false
      iex> Caustic.Utils.divides(2, 0)
      true
      iex> Caustic.Utils.divides(0, 0)
      true
  """
  def divides(a, 0) when is_integer(a), do: true
  def divides(0, b) when is_integer(b), do: false
  def divides(a, b) when is_integer(a) and is_integer(b), do: rem(b, a) == 0
  
  @doc """
  Solves the linear congruence ax = b (mod m).
  
  ## Examples
  
      iex> Caustic.Utils.linear_congruence_solve(1, 3, 4)
      [3]
      iex> Caustic.Utils.linear_congruence_solve(2, 1, 4)
      []
      iex> Caustic.Utils.linear_congruence_solve(2, 6, 4)
      [1, 3]
      iex> Caustic.Utils.linear_congruence_solve(0, 0, 3)
      [0, 1, 2]
      iex> Caustic.Utils.linear_congruence_solve(0, 1, 3)
      []
      iex> Caustic.Utils.linear_congruence_solve(0, 2, 3)
      []
      iex> Caustic.Utils.linear_congruence_solve(0, 3, 3)
      [0, 1, 2]
    
  """
  def linear_congruence_solve(a, b, m) when is_integer(a) and is_integer(m) and m > 0 do
    b = mod(b, m)
    d = gcd(a, m)
    if divides(d, b) do
      _linear_congruence_solve a, b, m, m
    else
      []
    end
  end

  defp _linear_congruence_solve(1, b, m, m_orig) do
    _linear_congruence_solutions [b], m, m_orig
  end
  
  defp _linear_congruence_solve(0, 0, m, m_orig) do
    _linear_congruence_solutions [0], 1, m_orig
  end
  
  defp _linear_congruence_solve(a, b, m, m_orig) do
    d = gcd(a, b)
    if d == 1 do
      _linear_congruence_solve a, b + m, m, m_orig
    else
      m = gcd(d, m)
      _linear_congruence_solve div(a, d), div(b, d), m, m_orig
    end
  end
  
  defp _linear_congruence_solutions(ns = [n | _], m, m_orig) when n + m >= m_orig do
    Enum.reverse(ns)
  end
  
  defp _linear_congruence_solutions(ns = [n | _], m, m_orig) do
    _linear_congruence_solutions [n + m | ns], m, m_orig
  end
  
  def linear_congruence_solve_explain(a, b, m) do
    result = linear_congruence_solve a, b, m
    a_str = if a == 1, do: "", else: "#{a}"
    eq_str = "#{a_str}x = #{b} (mod #{m})"
    if result == [] do
      IO.puts "The equation #{eq_str} has no solutions."
    else if length(result) == 1 do
      [n] = result
      IO.puts "The only solution of #{eq_str} is x = #{n}."
    else
      sol_str = Enum.join result, ", "
      IO.puts "The solutions of #{eq_str} are x = #{sol_str}."
    end end
  end
  
  def multiplication_table_mod_print(m) do
    table = multiplication_table_mod m
    
    row_labels = 0..(m - 1) |> Enum.to_list()
    col_labels = row_labels
    
    print_table(table, row_labels, col_labels)
  end
  
  def multiplication_table_mod(m) when is_integer(m) and m > 0 do
    0..(m - 1)
    |> Enum.map(fn n ->
      0..(m - 1)
      |> Enum.map(& mod(n * &1, m))
    end)
  end
  
  def exponentiation_table_mod(m) when is_integer(m) and m > 0 do
    residues = 0..(m - 1)
    
    residues
    |> Enum.map(fn n ->
      residues
      |> Enum.map(fn
        e when n == 0 and e == 0 -> "?"
        e -> pow_mod(n, e, m)
      end)
    end)
  end

  def exponentiation_table_mod_print(m) do
    table = exponentiation_table_mod m

    row_labels = 0..(m - 1) |> Enum.to_list()
    col_labels = row_labels

    print_table(table, row_labels, col_labels)
  end
  
  def print_table(table, row_labels, col_labels) do
    table_with_row_label = Enum.zip(row_labels, table)
    |> Enum.map(fn {row_label, row} -> [row_label | row] end)
    
    col_labels = ["" | col_labels]
    table_with_label = [col_labels | table_with_row_label]
    
    col_widths = List.zip(table_with_label)
    |> Enum.map(fn row ->
      row
      |> Tuple.to_list()
      |> Enum.map(&String.length(to_string(&1)))
      |> Enum.max()
    end)
    
    table_str = table_with_label
    |> Enum.map(fn row ->
      Enum.zip(row, col_widths)
      |> Enum.map(fn {col, width} -> String.pad_leading(to_string(col), width) end)
      |> Enum.join(" | ")
    end)
    |> Enum.join("\n")
    
    IO.puts(table_str)
  end
  
  @doc """
  Gets all the positive divisors of a number.
  
  ## Examples
  
      iex> Caustic.Utils.positive_divisors(1)
      [1]
      iex> Caustic.Utils.positive_divisors(3)
      [1, 3]
      iex> Caustic.Utils.positive_divisors(6)
      [1, 2, 3, 6]
      iex> Caustic.Utils.positive_divisors(-4)
      [1, 2, 4]
  """
  def positive_divisors(n) when n > 0 do
    factorize(n)
    |> subsets()
    |> Enum.map(fn factors -> Enum.reduce(factors, 1, &*/2) end)
    |> Enum.uniq()
  end
  
  def positive_divisors(n) when n < 0, do: positive_divisors(-n)
  
  @doc """
  Counts how many positive divisors an integer has. `d(n)`.
  
  ## Examples
  
      iex> Caustic.Utils.positive_divisors_count(1)
      1
      iex> Caustic.Utils.positive_divisors_count(3)
      2
      iex> Caustic.Utils.positive_divisors_count(6)
      4
  """
  def positive_divisors_count(n), do: length(positive_divisors(n))

  @doc """
  Sums the positive divisors of an integer. `σ(n)`.
  
  ## Examples
  
      iex> Caustic.Utils.positive_divisors_sum(1)
      1
      iex> Caustic.Utils.positive_divisors_sum(3)
      4
      iex> Caustic.Utils.positive_divisors_sum(6)
      12
  """
  def positive_divisors_sum(n), do: Enum.reduce(positive_divisors(n), 0, &+/2)

  @doc """
  Finds all subsets of a set (represented by a keyword list).

  ## Examples

      iex> Caustic.Utils.subsets([:a])
      [[], [:a]]
      iex> Caustic.Utils.subsets([:a, :b, :c])
      [[], [:a], [:b], [:c], [:a, :b], [:a, :c], [:b, :c], [:a, :b, :c]]
  """
  def subsets(s) do
    (0..length(s))
    |> Enum.flat_map(& subsets(s, &1))
  end

  @doc """
  Finds all subsets with cardinality `n` of a set (represented by a keyword list).

  ## Examples

      iex> members = ["nakai", "kusanagi", "mori", "kimura", "katori", "inagaki"]
      iex> Caustic.Utils.subsets(members, 3)
      [
        ["nakai", "kusanagi", "mori"],
        ["nakai", "kusanagi", "kimura"],
        ["nakai", "kusanagi", "katori"],
        ["nakai", "kusanagi", "inagaki"],
        ["nakai", "mori", "kimura"],
        ["nakai", "mori", "katori"],
        ["nakai", "mori", "inagaki"],
        ["nakai", "kimura", "katori"],
        ["nakai", "kimura", "inagaki"],
        ["nakai", "katori", "inagaki"],
        ["kusanagi", "mori", "kimura"],
        ["kusanagi", "mori", "katori"],
        ["kusanagi", "mori", "inagaki"],
        ["kusanagi", "kimura", "katori"],
        ["kusanagi", "kimura", "inagaki"],
        ["kusanagi", "katori", "inagaki"],
        ["mori", "kimura", "katori"],
        ["mori", "kimura", "inagaki"],
        ["mori", "katori", "inagaki"],
        ["kimura", "katori", "inagaki"]
      ]
  """
  def subsets(s, n) when n >= 0 do
    _subsets([], [{[], s, n}])
  end

  def _subsets(result, []), do: Enum.reverse(result)

  def _subsets(result, [{_chosen, candidates, n} | pattern_rest]) when n > length(candidates) do
    _subsets(result, pattern_rest)
  end

  def _subsets(result, [{chosen, candidates, n} | pattern_rest]) when n == length(candidates) do
    _subsets([Enum.reverse(chosen) ++ candidates | result], pattern_rest)
  end

  def _subsets(result, [{chosen, _candidates, n} | pattern_rest]) when n == 0 do
    _subsets([Enum.reverse(chosen) | result], pattern_rest)
  end

  def _subsets(result, [{chosen, [candidate | candidates_rest], n} | pattern_rest]) do
    pattern_1 = {[candidate | chosen], candidates_rest, n - 1}
    pattern_2 = {chosen, candidates_rest, n}
    _subsets(result, [pattern_1, pattern_2] ++ pattern_rest)
  end
  
end
