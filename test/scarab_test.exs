defmodule Test.Scarab do
  use ExUnit.Case

  setup_all do
    Application.ensure_all_started(:ex_aws)
    Application.ensure_all_started(:httpoison)

    defmodule FS do
      dir = :os.timestamp |> :erlang.phash2 |> to_string
      @path Path.join(System.tmp_dir!, dir)

      use Scarab, backend: Scarab.Backend.FS,
        config: %{path: @path}
    end

    defmodule S3 do
      use Scarab, backend: Scarab.Backend.S3,
                  config: %{bucket: "foo"}
    end

    :ok
  end

  for backend <- [FS, S3] do
    impl = Module.concat(__MODULE__, backend)

    test "#{inspect(backend)} - Repo.put(content)" do
      impl = unquote(impl)
      content = gen_content()

      {:ok, hash} = impl.put(content)
      {:ok, ^content} = impl.get(hash)
    end

    test "#{inspect(backend)} - Repo.link(namespace, name, hash)" do
      impl = unquote(impl)
      content = gen_content()
      namespace = gen_namespace()
      name = "link"

      {:ok, hash} = impl.put(content)
      :ok = impl.link(namespace, name, hash)
      {:ok, ^content} = impl.resolve(namespace, name)
      {:ok, ^content} = impl.resolve(namespace, hash)
      :ok = impl.unlink(namespace, name)
      {:error, :enoent} = impl.resolve(namespace, name)
    end

    test "#{inspect(backend)} - Repo.link(namespace, name, ref)" do
      impl = unquote(impl)
      content = gen_content()
      namespace = gen_namespace()
      name1 = "nested-link1"
      name2 = "nested-link2"

      {:ok, hash} = impl.put(content)
      :ok = impl.link(namespace, name1, hash)
      :ok = impl.link(namespace, name2, name1)
      {:ok, ^content} = impl.resolve(namespace, name1)
      {:ok, ^content} = impl.resolve(namespace, name2)
      {:ok, ^content} = impl.resolve(namespace, hash)

      :ok = impl.unlink(namespace, name1)
      {:error, :enoent} = impl.resolve(namespace, name1)
      {:error, :enoent} = impl.resolve(namespace, name2)

      :ok = impl.unlink(namespace, name2)
      {:error, :enoent} = impl.resolve(namespace, name2)
    end
  end

  defp gen_namespace() do
    :crypto.rand_bytes(18)
    |> Base.url_encode64()
  end

  defp gen_content do
    :crypto.rand_bytes(20)
  end
end
