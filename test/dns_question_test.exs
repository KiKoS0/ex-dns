defmodule ExDns.DnsQuestionTest do
  use ExUnit.Case

  alias ExDns.DnsQuestion

  describe "to_bytes/1" do
    test "correct packing" do
      question = %DnsQuestion{name: "example.com", type: 1, class: 1}

      assert DnsQuestion.to_bytes(question) |> IO.iodata_to_binary() ==
               "example.com" <> <<0, 1, 0, 1>>
    end
  end
end
