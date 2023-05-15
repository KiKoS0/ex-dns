defmodule ExDns.DnsHeaderTest do
  use ExUnit.Case

  describe "to_bytes/1" do
    test "correct packing" do
      header = %ExDns.DnsHeader{
        id: 0x1314,
        flags: 0,
        num_question: 0,
        num_answer: 0,
        num_authority: 0,
        num_additional: 0
      }

      assert ExDns.DnsHeader.to_bytes(header) |> IO.iodata_to_binary() ==
               <<19, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    end
  end
end
