# scarab [![Build Status](https://travis-ci.org/camshaft/scarab.svg?branch=master)](https://travis-ci.org/camshaft/scarab) [![Hex.pm](https://img.shields.io/hexpm/v/scarab.svg?style=flat-square)](https://hex.pm/packages/scarab) [![Hex.pm](https://img.shields.io/hexpm/dt/scarab.svg?style=flat-square)](https://hex.pm/packages/scarab)

content-addressable file storage for elixir

## Installation

`Scarab` is [available in Hex](https://hex.pm/docs/publish) and can be installed as:

  1. Add concerto your list of dependencies in `mix.exs`:

        def deps do
          [{:scarab, "~> 0.1.0"}]
        end

## Usage

Start by defining a repo:

```elixir
defmodule My.Repo do
  use Scarab, backend: Scarab.Backend.FS,
              config: %{path: ".repo"}
end
```

Available backends include:

- [S3](https://github.com/camshaft/scarab/blob/master/lib/scarab/backend/s3.ex) (AWS S3)
- [FS](https://github.com/camshaft/scarab/blob/master/lib/scarab/backend/fs.ex) (local filesystem)

Now we can put and get contents:

```elixir
{:ok, hash} = My.Repo.put("Hello, world!")

IO.inspect hash
## ":lDpwLQbzRZmu4fjajvn3KWAx1pk"

{:ok, "Hello, world!"} = My.Repo.get(hash)
```

We can also add namespaced links for easy lookup:

```elixir
{:ok, hash} = My.Repo.put("Hello, links!")
:ok = My.Repo.link("my-namespace", "my-link", hash)

My.Repo.resolve("my-namespace", "my-link") |> IO.inspect
## {:ok, "Hello, links!"}

My.Repo.unlink("my-namespace", "my-link")

My.Repo.resolve("my-namespace", "my-link") |> IO.inspect
## {:error, :enoent}
```
