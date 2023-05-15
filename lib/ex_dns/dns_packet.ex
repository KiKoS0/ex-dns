defmodule ExDns.DnsPacket do
  defstruct [:header, :questions, :answers, :authorities, :additionals]

  alias ExDns.DnsHeader

  def from_bytes(bytes) do
    {header = %DnsHeader{
       num_question: num_question,
       num_answer: num_answer,
       num_authority: num_authority,
       num_additional: num_additional
     }, rest} = ExDns.DnsHeader.from_bytes(bytes)

    {questions, rest} = get_all(rest, bytes, num_question, &ExDns.DnsQuestion.from_bytes/2)

    {answers, rest} = get_all(rest, bytes, num_answer, &ExDns.DnsRecord.from_bytes/2)

    {authorities, rest} = get_all(rest, bytes, num_authority, &ExDns.DnsRecord.from_bytes/2)

    {additionals, _} = get_all(rest, bytes, num_additional, &ExDns.DnsRecord.from_bytes/2)

    %ExDns.DnsPacket{
      header: header,
      questions: questions,
      answers: answers,
      authorities: authorities,
      additionals: additionals
    }
  end

  defp get_all(bytes, _, 0, _) do
    {[], bytes}
  end

  defp get_all(bytes, all_bytes, count, resolver) do
    {rec, rest} = resolver.(bytes, all_bytes)

    {next_recs, rest} = get_all(rest, all_bytes, count - 1, resolver)
    {[rec | next_recs], rest}
  end
end
