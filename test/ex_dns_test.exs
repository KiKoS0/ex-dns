defmodule ExDnsTest do
  use ExUnit.Case
  doctest ExDns

  describe "encode_dns_name/1" do
    test "correct encoding" do
      assert ExDns.encode_dns_name("google.com") |> IO.iodata_to_binary() ==
               <<6, "google", 3, "com", 0>>
    end
  end

  describe "build_query/2" do
    test "creates a valid query that gets back a response with 0 as reply code" do
      query = ExDns.build_query("www.example.com", 1)
      {:ok, socket} = :gen_udp.open(0, [:inet, :binary, {:active, false}])
      :gen_udp.send(socket, {8, 8, 8, 8}, 53, IO.iodata_to_binary(query))

      assert {:ok, {_ip, _port, <<(<<_::28>>), <<reply_code::4>>, (<<_::binary>>)>>}} =
               :gen_udp.recv(socket, 1024, 5000)

      :gen_udp.close(socket)

      assert reply_code == 0
    end
  end

  describe "lookup_domain/1" do
    test "returns valid ip address" do
      ip = ExDns.lookup_domain("example.com")
      assert :inet.is_ipv4_address(ip)
    end
  end
end
