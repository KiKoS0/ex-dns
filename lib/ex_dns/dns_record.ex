defmodule ExDns.DnsRecord do
  defstruct [:name, :type, :class, :ttl, :data, :raw_data]

  @type_a 1
  def type_a, do: @type_a
  @type_ns 2
  def type_ns, do: @type_ns

  @type_txt 16
  def type_txt, do: @type_txt

  @class_in 1
  def class_in, do: @class_in

  def from_bytes(bytes, all_bytes) do
    int_size = 2 * 8

    {name, rest} = ExDns.DnsQuestion.decode_name(bytes, all_bytes)

    <<type::integer-size(int_size), class::integer-size(int_size),
      ttl::integer-size(int_size * 2), data_len::integer-size(int_size), rest::binary>> = rest

    <<raw_data::bytes-size(data_len), rest::binary>> = rest

    data =
      case type do
        @type_a -> ip_bytes_to_inet_ip(raw_data)
        @type_ns -> ExDns.DnsQuestion.decode_name(raw_data, all_bytes) |> elem(0)
        _ -> raw_data
      end

    {%ExDns.DnsRecord{
       name: name,
       type: type,
       class: class,
       ttl: ttl,
       raw_data: raw_data,
       data: data
     }, rest}
  end

  def ip_bytes_to_string(
        <<d1::integer-size(8), d2::integer-size(8), d3::integer-size(8), d4::integer-size(8)>>
      ) do
    "#{d1}.#{d2}.#{d3}.#{d4}"
  end

  def ip_bytes_to_inet_ip(
        <<d1::integer-size(8), d2::integer-size(8), d3::integer-size(8), d4::integer-size(8)>>
      ) do
    {d1, d2, d3, d4}
  end
end
