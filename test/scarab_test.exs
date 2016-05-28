defmodule Test.Scarab.Backend.FS do
  use ExUnit.Case

  alias __MODULE__.Repo

  setup_all do
    Application.ensure_all_started(:ex_aws)
    Application.ensure_all_started(:httpoison)

    defmodule Repo do
      dir = :os.timestamp |> :erlang.phash2 |> to_string
      @path Path.join(System.tmp_dir!, dir)

      use Scarab, backend: Scarab.Backend.S3,
                  config: %{path: @path, bucket: "foo"}
    end

    :ok
  end

  test "Repo.put(content)" do
    content = gen_content()

    {:ok, hash} = Repo.put(content)
    {:ok, ^content} = Repo.get(hash)
  end

  test "Repo.link(namespace, name, hash)" do
    content = gen_content()
    namespace = gen_namespace()
    name = "link"

    {:ok, hash} = Repo.put(content)
    :ok = Repo.link(namespace, name, hash)
    {:ok, ^content} = Repo.resolve(namespace, name)
    {:ok, ^content} = Repo.resolve(namespace, hash)
    :ok = Repo.unlink(namespace, name)
    {:error, :enoent} = Repo.resolve(namespace, name)
  end

  test "Repo.link(namespace, name, ref)" do
    content = gen_content()
    namespace = gen_namespace()
    name1 = "nested-link1"
    name2 = "nested-link2"

    {:ok, hash} = Repo.put(content)
    :ok = Repo.link(namespace, name1, hash)
    :ok = Repo.link(namespace, name2, name1)
    {:ok, ^content} = Repo.resolve(namespace, name1)
    {:ok, ^content} = Repo.resolve(namespace, name2)
    {:ok, ^content} = Repo.resolve(namespace, hash)

    :ok = Repo.unlink(namespace, name1)
    {:error, :enoent} = Repo.resolve(namespace, name1)
    {:error, :enoent} = Repo.resolve(namespace, name2)

    :ok = Repo.unlink(namespace, name2)
    {:error, :enoent} = Repo.resolve(namespace, name2)
  end

  defp gen_namespace() do
    :crypto.rand_bytes(18)
    |> Base.url_encode64()
  end

  defp gen_content do
    :crypto.rand_bytes(20)
  end
end
