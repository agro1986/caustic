defmodule AgroLib.Utils do
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
    
      iex> AgroLib.Utils.base64_encode_char(0)
      "A"
      iex> AgroLib.Utils.base64_encode_char(5)
      "F"
      iex> AgroLib.Utils.base64_encode_char(26)
      "a"
      iex> AgroLib.Utils.base64_encode_char(31)
      "f"
      iex> AgroLib.Utils.base64_encode_char(52)
      "0"
      iex> AgroLib.Utils.base64_encode_char(57)
      "5"
      iex> AgroLib.Utils.base64_encode_char(62)
      "+"
      iex> AgroLib.Utils.base64_encode_char(63)
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
    
      iex> AgroLib.Utils.base64_decode_char("A")
      0
      iex> AgroLib.Utils.base64_decode_char("F")
      5
      iex> AgroLib.Utils.base64_decode_char("a")
      26
      iex> AgroLib.Utils.base64_decode_char("f")
      31
      iex> AgroLib.Utils.base64_decode_char("0")
      52
      iex> AgroLib.Utils.base64_decode_char("5")
      57
      iex> AgroLib.Utils.base64_decode_char("+")
      62
      iex> AgroLib.Utils.base64_decode_char("/")
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
  
      iex> AgroLib.Utils.base64_encode("Man")
      "TWFu"
      iex> AgroLib.Utils.base64_encode("Ma")
      "TWE="
      iex> AgroLib.Utils.base64_encode("M")
      "TQ=="
      iex> AgroLib.Utils.base64_encode("Man is distinguished, not only by his reason, but by this singular passion from other animals...")
      "TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlz\\r\\nIHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLi4u"
      iex> AgroLib.Utils.base64_encode("Man is distinguished, not only by his reason, but by this singular passion from other animals...", new_line: false)
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
  
      iex> AgroLib.Utils.base64_decode("TWFu")
      "Man"
      iex> AgroLib.Utils.base64_decode("TWE=")
      "Ma"
      iex> AgroLib.Utils.base64_decode("TQ==")
      "M"
      iex> AgroLib.Utils.base64_decode("TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlz\\r\\nIHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLi4u")
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
  
      iex> AgroLib.Utils.bitstring_to_array "Hey"
      [0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 1]
      iex> AgroLib.Utils.bitstring_to_array << 1 :: size(1), 0 :: size(1), 1 :: size(1) >>
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
  
      iex> AgroLib.Utils.pow(3, 9)
      19683
      iex> AgroLib.Utils.pow(2, 8)
      256
      iex> AgroLib.Utils.pow(2, 256)
      115792089237316195423570985008687907853269984665640564039457584007913129639936
      iex> AgroLib.Utils.pow(2, -2)
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
  
      iex> AgroLib.Utils.bitstring_to_integer(<<255, 255>>)
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
  
      iex> AgroLib.Utils.base58_encode("801e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aeddc47e83ff")
      "5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn"
      iex> AgroLib.Utils.base58_encode(<<57>>, convert_from_hex: false)
      "z"
      iex> AgroLib.Utils.base58_encode(63716817338599314535577169638518475271320430400871647684951348108655027767484127754748927)
      "5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn"
      iex> AgroLib.Utils.base58_encode("0x000001")
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
  
      iex> AgroLib.Utils.base58_decode("5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn")
      "0x801e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aeddc47e83ff"
      iex> AgroLib.Utils.base58_decode("5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn", prefix: false)
      "801e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aeddc47e83ff"
  """
  def base58_decode(str, opts \\ []), do: base58_to_integer(str) |> to_string(16, opts)
  
  @doc """
  Encodes a binary to its base58check representation.
  
  Possible values for version: `:address`, `:address_p2sh`, `:address_testnet`,
  `private_key_wif`, `private_key_bip38_encrypted`, `public_key_bit32_extended`
  
  Can also use custom binary version.
  
  ## Examples
  
      iex> AgroLib.Utils.base58check_encode("0x1e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aedd", :private_key_wif)
      "5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn"
      iex> AgroLib.Utils.base58check_encode(<<AgroLib.Utils.to_integer("0x1e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aedd")::size(256)>>, :private_key_wif, convert_from_hex: false)
      "5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn"
      iex> AgroLib.Utils.base58check_encode(<<AgroLib.Utils.to_integer("0x1e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aedd")::size(256), 0x01>>, :private_key_wif, convert_from_hex: false)
      "KxFC1jmwwCoACiCAWZ3eXa96mBM6tb3TYzGmf6YwgdGWZgawvrtJ"
      iex> AgroLib.Utils.base58check_encode(<<AgroLib.Utils.to_integer("1E99423A4ED27608A15A2616A2B0E9E52CED330AC530EDCC32C8FFC6A526AEDD", 16)::size(256), 0x01>>, :private_key_wif, convert_from_hex: false)
      "KxFC1jmwwCoACiCAWZ3eXa96mBM6tb3TYzGmf6YwgdGWZgawvrtJ"
      iex> AgroLib.Utils.base58check_encode("f5f2d624cfb5c3f66d06123d0829d1c9cebf770e", :address)
      "1PRTTaJesdNovgne6Ehcdu1fpEdX7913CK"
      iex> AgroLib.Utils.base58check_encode("000000cb23faea20aa20f02a02955ffd1d785518", :address)
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
  
      iex> AgroLib.Utils.base58check_decode "5J3mBbAH58CpQ3Y5RNJpUKPE62SQ5tfcvU2JpbnkeyhfsYB1Jcn"
      {:ok, <<196, 126, 131, 255>>, "1e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aedd", :private_key_wif}
      iex> AgroLib.Utils.base58check_decode "1J7mdg5rbQyUHENYdx39WVWK7fsLpEoXZy"
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
  
      iex> AgroLib.Utils.bitcoin_private_key_to_wif("1e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aedd")
      "KxFC1jmwwCoACiCAWZ3eXa96mBM6tb3TYzGmf6YwgdGWZgawvrtJ"
      iex> AgroLib.Utils.bitcoin_private_key_to_wif("1e99423a4ed27608a15a2616a2b0e9e52ced330ac530edcc32c8ffc6a526aedd", compressed: false)
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
  
      iex> AgroLib.Utils.string_index_of("Hello", "H")
      0
      iex> AgroLib.Utils.string_index_of("Hello", "h")
      nil
      iex> AgroLib.Utils.string_index_of("Hello", "l")
      2
  """
  def string_index_of(str, c), do: _string_index_of(str, c, 0)
  defp _string_index_of(<<>>, _c, _), do: nil
  defp _string_index_of(<<next, _rest :: binary>>, c, i) when << next >> == c, do: i
  defp _string_index_of(<<_next, rest :: binary>>, c, i), do: _string_index_of(rest, c, i + 1)

  @doc """
  Find the digits of a nonnegative integer `n` in a particular `base`.
  
  ## Examples
      iex> AgroLib.Utils.to_digits(321, 10)
      [3, 2, 1]
      iex> AgroLib.Utils.to_digits(5, 2)
      [1, 0, 1]
      iex> AgroLib.Utils.to_digits(255, 16)
      [15, 15]
      iex> AgroLib.Utils.to_digits(0, 8)
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
#    iex> AgroLib.Utils.to_string(8, 10)
#    "8"
#    iex> AgroLib.Utils.to_string(15, 16)
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
  
      iex> AgroLib.Utils.to_string(255, 16)
      "0xff"
      iex> AgroLib.Utils.to_string(255, 16, prefix: false)
      "ff"
      iex> AgroLib.Utils.to_string(5, 2)
      "0b101"
  """
  def to_string(n, base, opts \\ []) do
    opts = opts ++ [prefix: true]
    str = to_digits(n, base) |> Enum.map_join(&_to_string(&1, base))
    
    prefix = if opts[:prefix], do: Map.get(@base_prefixes, base, ""), else: "" 
    prefix <> str
  end

  defp _to_string(n, _base) when n <= 9, do: to_string(n)
  defp _to_string(n, _base), do: <<?a + n - 10>>
  
  @doc """
  Parse a string which can be in any base to integer, autodetecting the base using the prefix.
  
  ## Examples
  
      iex> AgroLib.Utils.to_integer("0xff")
      255
      iex> AgroLib.Utils.to_integer("0b101")
      5
      iex> AgroLib.Utils.to_integer("321")
      321
  """
  def to_integer(str) do
    base = get_base(String.downcase(str))
    to_integer(str, base)
  end

  @doc """
  Parse a string which can be in any base to integer, specifying the base.
  
  ## Examples
  
      iex> AgroLib.Utils.to_integer("ff", 16)
      255
      iex> AgroLib.Utils.to_integer("101", 2)
      5
      iex> AgroLib.Utils.to_integer("755", 8)
      493
      iex> AgroLib.Utils.to_integer("321", 10)
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
  
      iex> AgroLib.Utils.get_base("0xabf")
      16
      iex> AgroLib.Utils.get_base("0b101")
      2
      iex> AgroLib.Utils.get_base("321")
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
  
      iex> AgroLib.Utils.hex_remove_prefix("0xff")
      "ff"
      iex> AgroLib.Utils.hex_remove_prefix("0XFF")
      "FF"
      iex> AgroLib.Utils.hex_remove_prefix("ff")
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
  ## Examples
  
      iex> AgroLib.Utils.mod(0, 3)
      0
      iex> AgroLib.Utils.mod(-27, 13)
      12
  """
  def mod(x, y) when x >= 0, do: rem(x, y);
  def mod(x, y) when x < 0, do: rem(x, y) + y;
end
