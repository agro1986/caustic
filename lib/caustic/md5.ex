defmodule Caustic.Md5 do
  alias Caustic.Utils

  use Bitwise

  # md5 can only calculate multiples of block size
  # will pad to create a valid block size
  @block_size_byte 64
  #@block_size_bit 512

  #@output_size_byte 16
  #@output_size_bit 128

  # the length of input (in bit) is
  # represented at the end of block
  @length_field_size_byte 8
  @length_field_size_bit 64

  @target_size_byte @block_size_byte - @length_field_size_byte
  #@target_size_bit @block_size_bit - @length_field_size_bit

  @length_max_bit 0xffffffffffffffff
  @addition_modulo 0xffffffff

  @a0 0x67452301
  @b0 0xefcdab89
  @c0 0x98badcfe
  @d0 0x10325476

  # shift amount per operation
  @s [7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22, # round 1
      5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20, # round 2
      4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23, # round 3
      6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21] # round 4

  # addition constant per operation
  # k[i] = floor(2^32 * abs(sin(i + 1))), 0 <= i <= 63
  @k [0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, # round 1
      0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501, # round 1
      0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, # round 1
      0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821, # round 1
      0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, # round 2
      0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8, # round 2
      0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, # round 2
      0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a, # round 2
      0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c, # round 3
      0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70, # round 3
      0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05, # round 3
      0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665, # round 3
      0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, # round 4
      0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1, # round 4
      0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, # round 4
      0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391] # round 4

  @doc """
  Calculate the md5 hash of a message.

  ## Examples

      iex> Caustic.Md5.hash("The quick brown fox jumps over the lazy dog")
      "9e107d9d372bb6826bd81d3542a419d6"

      iex> Caustic.Md5.hash("The quick brown fox jumps over the lazy dog.")
      "e4d909c290d0fb1ca068ffaddf22cbd0"

      iex> Caustic.Md5.hash("The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.")
      "f168d89e05b664041ee6745f050caa4b"

      iex> Caustic.Md5.hash("")
      "d41d8cd98f00b204e9800998ecf8427e"

      iex> Caustic.Md5.hash("a")
      "0cc175b9c0f1b6a831c399e269772661"

      iex> Caustic.Md5.hash("abc")
      "900150983cd24fb0d6963f7d28e17f72"

      iex> Caustic.Md5.hash("12345678901234567890123456789012345678901234567890123456789012345678901234567890")
      "57edf4a22be3c955ac49da2e2107b67a"
  """
  def hash(str) do
    {a, b, c, d} = _hash_padded(pad(str))
    <<a :: little-size(32), b :: little-size(32), c :: little-size(32), d :: little-size(32)>>
    |> Base.encode16(case: :lower)
  end

  defp _append_length(str_padded, len_byte) do
    length_field = rem(len_byte * 8, @length_max_bit)
    <<str_padded :: binary, length_field :: little-size(@length_field_size_bit)>>
  end

  defp _hash_padded(str) do
    _hash_padded(str, @a0, @b0, @c0, @d0)
  end

  defp _hash_padded("", a, b, c, d), do: {a, b, c, d}

  defp _hash_padded(<<chunk :: binary-size(@block_size_byte), rest :: binary>>, a, b, c, d) do
    words = _chunk_to_words(chunk)
    {a1, b1, c1, d1} = _hash_round(words, a, b, c, d)
    a = clip(a + a1)
    b = clip(b + b1)
    c = clip(c + c1)
    d = clip(d + d1)
    _hash_padded(rest, a, b, c, d)
  end

  defp _chunk_to_words(chunk), do: _chunk_to_words(chunk, [])

  defp _chunk_to_words("", words) do
    Enum.reverse words
  end

  defp _chunk_to_words(<<word :: little-size(32), rest :: binary>>, words) do
    _chunk_to_words(rest, [word | words])
  end

  defp _hash_round(words, a, b, c, d, i \\ 0)
  defp _hash_round(_words, a, b, c, d, 64) do
    {a, b, c, d}
  end
  defp _hash_round(words, a, b, c, d, i) do
    f = _f(b, c, d, i)
    g = _g(words, i)
    k = Enum.at(@k, i)
    f = clip(f + a + k + g)
    after_rotate = _left_rotate(f, Enum.at(@s, i))
    a = d
    d = c
    c = b
    b = clip(b + after_rotate)
    _hash_round(words, a, b, c, d, i + 1)
  end

  defp _f(b, c, d, i) when 0 <= i and i <= 15, do: f0(b, c, d)
  defp _f(b, c, d, i) when 16 <= i and i <= 31, do: f1(b, c, d)
  defp _f(b, c, d, i) when 32 <= i and i <= 47, do: f2(b, c, d)
  defp _f(b, c, d, i) when 48 <= i and i <= 63, do: f3(b, c, d)

  defp _g(words, i) when 0 <= i and i <= 15, do: Enum.at(words, i)
  defp _g(words, i) when 16 <= i and i <= 31, do: Enum.at(words, rem(5 * i + 1, 16))
  defp _g(words, i) when 32 <= i and i <= 47, do: Enum.at(words, rem(3 * i + 5, 16))
  defp _g(words, i) when 48 <= i and i <= 63, do: Enum.at(words, rem(7 * i, 16))

  defp _left_rotate(f, n) do
    clip((f <<< n) ||| (f >>> (32 - n)))
  end

  @doc """
  The nonlinear function used in round 1 (of 4) of a block processing.
  """
  def f0(b, c, d) do
    (b &&& c) ||| ((~~~b) &&& d)
  end

  @doc """
  The nonlinear function used in round 2 (of 4) of a block processing.
  """
  def f1(b, c, d) do
    (b &&& d) ||| (c &&& (~~~d))
  end

  @doc """
  The nonlinear function used in round 3 (of 4) of a block processing.
  """
  def f2(b, c, d) do
    b ^^^ c ^^^ d
  end

  @doc """
  The nonlinear function used in round 4 (of 4) of a block processing.
  """
  def f3(b, c, d) do
    c ^^^ (b ||| (~~~d))
  end

  @doc """
  Perform a length extension attack.
  https://blog.skullsecurity.org/2012/everything-you-need-to-know-about-hash-length-extension-attacks

  ## Examples

      iex> secret = "THE_SUPER_SECRET"
      iex> secret_length = byte_size(secret)
      iex> message = "action=delete&id=123"
      iex> signature = Caustic.Md5.hash(secret <> message)
      iex> append = "&id=999"
      iex> message_attack = message <> <<0x80, 0x00 :: size(152), (secret_length + byte_size(message)) * 8 :: little-size(64)>> <> append
      iex> signature_attack = Caustic.Md5.hash(secret <> message_attack)
      iex> {message_attack, signature_attack} == Caustic.Md5.length_extension_attack(message, signature, secret_length, append)
      true
  """
  def length_extension_attack(message, signature, secret_length_byte, append_message) do
    message_with_secret = String.duplicate("?", secret_length_byte) <> message
    message_with_secret_padded = pad(message_with_secret)
    length_original = byte_size(message_with_secret_padded)

    message_with_secret_padded_appended = message_with_secret_padded <> append_message
    <<_ :: binary-size(secret_length_byte), message_appended :: binary>> = message_with_secret_padded_appended

    <<a_str :: binary-size(8), b_str :: binary-size(8), c_str :: binary-size(8), d_str :: binary-size(8)>> = signature
    a = hex_to_uint32_little_endian(a_str)
    b = hex_to_uint32_little_endian(b_str)
    c = hex_to_uint32_little_endian(c_str)
    d = hex_to_uint32_little_endian(d_str)

    message_with_secret_padded_appended_padded = pad(message_with_secret_padded_appended)
    <<_ :: binary-size(length_original), message_delta :: binary>> = message_with_secret_padded_appended_padded

    {a, b, c, d} = _hash_padded(message_delta, a, b, c, d)

    message_appended_hash = <<a :: little-size(32), b :: little-size(32), c :: little-size(32), d :: little-size(32)>>
    |> Base.encode16(case: :lower)

    {message_appended, message_appended_hash}
  end

  @doc """
  Pad a binary and append original message length at the end.

  The length field is a 64 bit in little endian encoding, so the
  written length is modulo 2^64.

  md5 only works with a block size in multiple of 512 bit, so
  the message is optionally padded such that message <> padding <> length
  is in that multiple. The padding is a single '1' bit followed
  by as much '0' bits as needed.
  """
  def pad(str) do
    len_byte = byte_size(str)
    pad_byte = Utils.mod(@target_size_byte - len_byte, @block_size_byte)
    str = pad_zero(str, pad_byte)
    _append_length(str, len_byte)
  end

  @doc """
  Pad a binary with a single '1' bit and then with as much '0' bits as needed.
  """
  def pad_zero(str, 0), do: str
  def pad_zero(str, pad_byte) do
    zero_pad_bit = pad_byte * 8 - 1
    <<str :: binary, 1 :: size(1), 0 :: size(zero_pad_bit)>>
  end

  @doc """
  Clip a number to 32-bit.
  """
  def clip(n), do: n &&& @addition_modulo

  @doc """
  ## Examples

  iex> Caustic.Md5.hex_to_uint32_little_endian("6036708e")
  2389718624
  """
  def hex_to_uint32_little_endian(str) do
    binary = Base.decode16!(str, case: :lower)
    <<n :: little-size(32)>> = binary
    n
  end


end