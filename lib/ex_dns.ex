defmodule ExDns do
  @moduledoc """
  Documentation for `ExDns`.

  An Elixir toy version of a DNS resolver.
  Following the Wizard zine write-up by Julia Evans.
  https://implement-dns.wizardzines.com/index.html
  """

  alias ExDns.{DnsHeader, DnsQuestion, DnsRecord, DnsPacket}
  require Logger

  @a_root_ns_ip {198, 41, 0, 4}

  def encode_dns_name(name) do
    [
      name
      |> String.split(".")
      |> Stream.map(&(<<String.length(&1)>> <> &1))
      |> Enum.join(""),
      <<0>>
    ]
  end

  def build_query(domain_name, record_type) do
    encoded_domain = encode_dns_name(domain_name)

    header = %DnsHeader{id: :rand.uniform(65535), flags: 0, num_question: 1}
    question = %DnsQuestion{name: encoded_domain, type: record_type, class: DnsRecord.class_in()}

    [DnsHeader.to_bytes(header), DnsQuestion.to_bytes(question)]
  end

  def send_query(ip_address, domain_name, record_type) do
    query = build_query(domain_name, record_type)
    {:ok, socket} = :gen_udp.open(0, [:binary, {:active, false}])
    :gen_udp.send(socket, ip_address, 53, query)
    {:ok, {_ip, _port, response}} = :gen_udp.recv(socket, 1024, 5000)

    DnsPacket.from_bytes(response)
  end

  def lookup_domain(domain_name) do
    query = build_query(domain_name, DnsRecord.type_a())
    {:ok, socket} = :gen_udp.open(0, [:binary, {:active, false}])
    :gen_udp.send(socket, {8, 8, 8, 8}, 53, query)
    {:ok, {_ip, _port, response}} = :gen_udp.recv(socket, 1024, 5000)

    %DnsPacket{answers: [%{data: ip} | _]} = DnsPacket.from_bytes(response)

    ip
  end

  @type supported_record_type :: :a | :ns | :cname

  defp to_record_type(type) do
    %{a: DnsRecord.type_a(), ns: DnsRecord.type_ns(), cname: DnsRecord.type_cname()}[type]
  end

  @doc """
  Resolves a domain name to an IP address.

  ## Examples

      iex> ExDns.resolve "twitter.com", :a

  ### CNAME example

        iex> ExDns.resolve "www.facebook.com", :a

  """

  @spec resolve(String.t(), supported_record_type(), :inet.ip4_address()) :: :inet.ip4_address()
  def resolve(domain_name, record_type, ns_ip \\ @a_root_ns_ip, opts \\ []) do
    cached = not Keyword.get(opts, :force, false) && ExDns.Cache.get(domain_name)
    if cached, do: cached, else: do_resolve(domain_name, record_type, ns_ip, opts)
  end

  defp do_resolve(domain_name, record_type, ns_ip, opts) do
    Logger.debug("Resolving #{inspect(domain_name)} with #{inspect(ns_ip)}")

    query = build_query(domain_name, to_record_type(record_type))
    {:ok, socket} = :gen_udp.open(0, [:binary, {:active, false}])
    :gen_udp.send(socket, ns_ip, 53, query)
    {:ok, {_ip, _port, response}} = :gen_udp.recv(socket, 1024, 5000)

    packet = DnsPacket.from_bytes(response)

    cond do
      ip = get_ip(packet) ->
        ExDns.Cache.put(domain_name, ip.data, ip.ttl)
        ip.data

      ns_ip = get_ns_ip(packet) ->
        resolve(domain_name, record_type, ns_ip.data, opts)

      ns = get_ns(packet) ->
        ns_ip = resolve(ns.data, record_type, opts)
        result = resolve(domain_name, record_type, ns_ip, opts)
        ExDns.Cache.put(domain_name, result, ns.ttl)
        result

      cname = get_cname(packet) ->
        result = resolve(cname.data, record_type, ns_ip, opts)
        ExDns.Cache.put(domain_name, result, cname.ttl)
        result

      true ->
        raise "Could not resolve #{inspect(domain_name)}"
    end
  end

  defp get_ip(packet), do: find_record_in(packet, :answers, DnsRecord.type_a())
  defp get_cname(packet), do: find_record_in(packet, :answers, DnsRecord.type_cname())
  defp get_ns_ip(packet), do: find_record_in(packet, :additionals, DnsRecord.type_a())
  defp get_ns(packet), do: find_record_in(packet, :authorities, DnsRecord.type_ns())

  defp find_record_in(packet, property, value) do
    Enum.find(get_in(packet, [Access.key!(property)]), fn
      %{type: ^value} -> true
      _ -> false
    end)
  end
end
