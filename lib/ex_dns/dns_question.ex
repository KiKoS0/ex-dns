defmodule ExDns.DnsQuestion do
  defstruct [:name, :type, :class]

  import Bitwise

  def to_bytes(%ExDns.DnsQuestion{name: name, type: type, class: class}) do
    int_size = 2 * 8

    [name, <<type::integer-size(int_size)>>, <<class::integer-size(int_size)>>]
  end

  def from_bytes(bytes, all_bytes) do
    int_size = 2 * 8

    {name, rest} = decode_name(bytes, all_bytes)

    <<(<<type::integer-size(int_size)>>), <<class::integer-size(int_size)>>, (<<rest::binary>>)>> =
      rest

    {%ExDns.DnsQuestion{name: name, type: type, class: class}, rest}
  end

  def decode_name(bytes, all_bytes) do
    {val, rest} = do_decode_name(bytes, all_bytes)
    {Enum.join(val, "."), rest}
  end

  def do_decode_name(<<0::8, rest::binary>>, _) do
    {[], rest}
  end

  # Decode compressed name
  def do_decode_name(<<size::8, pointer_byte::8, rest::binary>>, all_bytes)
      when (size &&& 0b11000000) > 0 do
    <<offset::16>> = <<size &&& 0b00111111, pointer_byte>>
    <<_::bytes-size(offset), backtracked_rest::binary>> = all_bytes

    {part, _} = decode_name(backtracked_rest, all_bytes)

    {[part], rest}
  end

  def do_decode_name(<<size::8, rest::binary>>, all_bytes) do
    <<part::binary-size(size), rest::binary>> = rest
    {next, rest} = do_decode_name(rest, all_bytes)
    {[part | next], rest}
  end
end
