defmodule Test.Scarab do
  use ExUnit.Case

  setup_all do
    Application.ensure_all_started(:con_cache)
    Application.ensure_all_started(:ex_aws)
    Application.ensure_all_started(:httpoison)

    ConCache.start_link([], [name: __MODULE__])
    dir = :os.timestamp |> :erlang.phash2 |> to_string
    path = Path.join(System.tmp_dir!, dir)

    defmodule FS do
      @path path

      use Scarab, backend: Scarab.Backend.FS,
                  config: %{path: @path}
    end

    defmodule S3 do
      use Scarab, backend: Scarab.Backend.S3,
                  config: %{bucket: "scarab.test"}
    end

    defmodule FSCache do
      @path path

      use Scarab, backend: Scarab.Backend.FS,
                           config: %{path: @path}

      use Scarab.Middleware.Cache.FS, path: "#{@path}/cache"
    end

    defmodule CCache do
      @path path

      use Scarab, backend: Scarab.Backend.FS,
        config: %{path: @path}

      use Scarab.Middleware.Cache.ConCache, cache: Test.Scarab
    end

    defmodule CCacheNoLink do
      @path path

      use Scarab, backend: Scarab.Backend.FS,
        config: %{path: @path}

      use Scarab.Middleware.Cache.ConCache, cache: Test.Scarab, link_ttl: false
    end

    defmodule MultiCache do
      @path path

      use Scarab, backend: Scarab.Backend.FS,
        config: %{path: @path}

      use Scarab.Middleware.Cache.FS, path: "#{@path}/cache"
      use Scarab.Middleware.Cache.ConCache, cache: Test.Scarab
    end

    :ok
  end

  for backend <- [FS, S3, FSCache, CCache, CCacheNoLink, MultiCache] do
    impl = Module.concat(__MODULE__, backend)

    test "#{inspect(backend)} - Repo.put(content)" do
      impl = unquote(impl)
      content = gen_content()

      assert {:ok, hash} = impl.put(content)
      assert {:ok, ^content} = impl.get(hash)
    end

    test "#{inspect(backend)} - Repo.link(namespace, name, hash)" do
      impl = unquote(impl)
      content = gen_content()
      namespace = gen_namespace()
      name = "link"

      assert {:ok, hash} = impl.put(content)
      assert :ok = impl.link(namespace, name, hash)
      assert {:ok, ^content} = impl.resolve(namespace, name)
      assert {:ok, ^content} = impl.resolve(namespace, hash)
      assert :ok = impl.unlink(namespace, name)
      assert {:error, :enoent} = impl.resolve(namespace, name)
    end

    test "#{inspect(backend)} - Repo.link(namespace, name, ref)" do
      impl = unquote(impl)
      content = gen_content()
      namespace = gen_namespace()
      name1 = "nested-link1"
      name2 = "nested-link2"

      assert {:ok, hash} = impl.put(content)
      assert :ok = impl.link(namespace, name1, hash)
      assert :ok = impl.link(namespace, name2, name1)
      assert {:ok, ^content} = impl.resolve(namespace, name1)
      assert {:ok, ^content} = impl.resolve(namespace, name2)
      assert {:ok, ^content} = impl.resolve(namespace, hash)

      assert :ok = impl.unlink(namespace, name1)
      assert {:error, :enoent} = impl.resolve(namespace, name1)
      assert {:error, :enoent} = impl.resolve(namespace, name2)

      assert :ok = impl.unlink(namespace, name2)
      assert {:error, :enoent} = impl.resolve(namespace, name2)
    end

    test "#{inspect(backend)} - relink" do
      impl = unquote(impl)
      content1 = gen_content()
      content2 = gen_content()
      namespace = gen_namespace()

      name = "link"

      assert {:ok, hash1} = impl.put(content1)
      assert {:ok, hash2} = impl.put(content2)
      assert :ok = impl.link(namespace, name, hash1)
      assert {:ok, ^content1} = impl.resolve(namespace, name)
      assert :ok = impl.link(namespace, name, hash2)
      assert {:ok, ^content2} = impl.resolve(namespace, name)
    end
  end

  defp gen_namespace() do
    :crypto.strong_rand_bytes(18)
    |> Base.url_encode64()
  end

  defp gen_content do
    :crypto.strong_rand_bytes(20)
  end
end
