defmodule Scarab.Middleware.Cache.Base do
  defmacro __using__(opts) do
    module = opts[:module]
    config = opts[:config]
    link_max_age =
      case Keyword.fetch(opts, :link_ttl) do
        {:ok, value} when not is_nil(value) ->
          value
        _ ->
          :timer.seconds(30)
      end

    quote do
      defoverridable [__put__: 2, get: 1, __purge__: 1]

      alias unquote(module), as: Cache

      def __put__(hash, content) do
        Cache.purge(unquote(config), hash)
        super(hash, content)
      end

      def get(hash) do
        Cache.get_or_put(unquote(config), hash, &super/1)
      end

      def __purge__(hash) do
        Cache.purge(unquote(config), hash)
        super(hash)
      end

      if !(unquote(link_max_age) in [nil, false, 0]) do
        defoverridable [__get_link__: 1, __link__: 2, __unlink__: 1]

        def __get_link__(hash) do
          Cache.get_or_put_link(unquote(config), hash, unquote(link_max_age), &super/1)
        end

        def __link__(hash, ref) do
          Cache.purge(unquote(config), hash)
          super(hash, ref)
        end

        def __unlink__(hash) do
          Cache.purge(unquote(config), hash)
          super(hash)
        end
      end
    end
  end
end
