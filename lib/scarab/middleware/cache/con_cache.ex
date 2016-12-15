if Code.ensure_loaded?(ConCache) do
  defmodule Scarab.Middleware.Cache.ConCache do
    defmacro __using__(opts) do
      quote do
        use Scarab.Middleware.Cache.Base, [
          module: unquote(__MODULE__),
          config: %{unquote_splicing([
                     name: (opts[:cache] || throw :missing_cache),
                     touch_on_read: !!opts[:touch_on_read],
                     ttl: opts[:ttl] || :timer.minutes(5),
                   ])},
          link_ttl: unquote(opts[:link_ttl])
        ]
      end
    end

    def get_or_put(%{name: name, ttl: ttl, touch_on_read: tor}, ":" <> key = hash, parent) do
      tor && ConCache.touch(name, key)
      get_or_store(name, ttl, hash, parent)
    end

    def get_or_put_link(%{name: name}, hash, ttl, parent) do
      get_or_store(name, ttl, hash, parent)
    end

    defp get_or_store(name, ttl, ":" <> key = hash, parent) do
      ConCache.get_or_store(name, key, fn ->
        case parent.(hash) do
          {:ok, bin} ->
            item(bin, ttl)
          error ->
            error
        end
      end) |> wrap()
    end

    defp item(bin, nil) do
      bin
    end
    defp item(bin, ttl) do
      %ConCache.Item{
        value: bin,
        ttl: ttl
      }
    end

    defp wrap({:error, _} = error) do
      error
    end
    defp wrap(value) do
      {:ok, value}
    end

    def purge(%{name: name}, ":" <> key) do
      ConCache.delete(name, key)
    end
  end
end
