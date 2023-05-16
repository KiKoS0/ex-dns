defmodule ExDns.Cache do
  @moduledoc """
  Cache for DNS records.
  """

  use GenServer

  @ets_name :dns_cache

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    :ets.new(@ets_name, [:set, :public, :named_table])

    {:ok, nil}
  end

  def put(domain, value, ttl_seconds) do
    domain = String.downcase(domain)

    expiration = :os.system_time(:millisecond) + ttl_seconds * 1000
    :ets.insert(@ets_name, {domain, value, expiration})
    expiration
  end

  def get(domain) do
    domain = String.downcase(domain)

    case :ets.lookup(@ets_name, domain) do
      [{^domain, value, expiration}] -> check_freshness(value, expiration)
      [] -> nil
    end
  end

  defp check_freshness(result, expiration) do
    if expiration > :os.system_time(:millisecond), do: result, else: nil
  end
end
