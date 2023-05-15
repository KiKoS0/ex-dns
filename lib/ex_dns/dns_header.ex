defmodule ExDns.DnsHeader do
  defstruct [
    :id,
    :flags,
    num_question: 0,
    num_answer: 0,
    num_authority: 0,
    num_additional: 0
  ]

  def to_bytes(%ExDns.DnsHeader{
        id: id,
        flags: flags,
        num_question: num_question,
        num_additional: num_additional,
        num_authority: num_authority,
        num_answer: num_answer
      }) do
    int_size = 2 * 8

    [
      <<id::integer-size(int_size)>>,
      <<flags::integer-size(int_size)>>,
      <<num_question::integer-size(int_size)>>,
      <<num_answer::integer-size(int_size)>>,
      <<num_authority::integer-size(int_size)>>,
      <<num_additional::integer-size(int_size)>>
    ]
  end

  def from_bytes(bytes) do
    int_size = 2 * 8

    <<id::integer-size(int_size), flags::integer-size(int_size),
      num_question::integer-size(int_size), num_answer::integer-size(int_size),
      num_authority::integer-size(int_size), num_additional::integer-size(int_size),
      rest::binary>> = bytes

    {
      %ExDns.DnsHeader{
        id: id,
        flags: flags,
        num_question: num_question,
        num_answer: num_answer,
        num_authority: num_authority,
        num_additional: num_additional
      },
      rest
    }
  end
end
