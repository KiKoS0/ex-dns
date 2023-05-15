# ExDns

An Elixir toy version of a DNS resolver. Following the Wizard zine write-up by Julia Evans.

https://implement-dns.wizardzines.com/index.html

## Usage

```elixir
  iex> ExDns.resolve "twitter.com", ExDns.DnsRecord.type_a
```