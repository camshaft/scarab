defmodule Scarab do
  defmacro __using__(opts) do
    backend = opts[:backend]
    config = opts[:config]

    quote do
      @scarab_backend unquote(backend)
      @scarab_config unquote(config)

      def put(content) do
        hash = Scarab.__hash__(content)
        case __put__(hash, content) do
          :ok ->
            {:ok, hash}
          error ->
            error
        end
      end

      def __put__(":" <> hash, content) do
        @scarab_backend.put(hash, content, @scarab_config)
      end

      def get(":" <> hash) do
        @scarab_backend.get(hash, @scarab_config)
      end

      def __get_link__(":" <> hash) do
        @scarab_backend.get(hash, @scarab_config)
      end

      def resolve(namespace, ref)
      def resolve(_, ":" <> _ = hash) do
        get(hash)
      end
      def resolve(namespace, link) when is_binary(link) do
        hash = Scarab.__hash_link__(namespace, link)
        case __get_link__(hash) do
          {:ok, ref} ->
            resolve(namespace, ref)
          error ->
            error
        end
      end

      def link(namespace, name, ref)
      def link(_namespace, ":" <> _ = name, _ref) do
        {:error, {:invalid_link, name}}
      end
      def link(namespace, name, ref) do
        namespace
        |> Scarab.__hash_link__(name)
        |> __link__(ref)
      end

      def __link__(":" <> hash, ref) do
        @scarab_backend.link(hash, ref, @scarab_config)
      end

      def unlink(namespace, name) do
        namespace
        |> Scarab.__hash_link__(name)
        |> __unlink__()
      end

      def __unlink__(":" <> hash) do
        @scarab_backend.delete(hash, @scarab_config)
      end

      def purge(namespace, ref)
      def purge(_, ":" <> hash) do
        __purge__(hash)
      end
      def purge(namespace, link) do
        namespace
        |> Scarab.__hash_link__(link)
        |> __purge__()
      end

      def __purge__(_hash) do
        :ok
      end

      def valid_link?(":" <> _), do: false
      def valid_link?(_), do: true
    end
  end

  def __hash__(content) do
    hash = :crypto.hash(:sha, content)
    |> Base.url_encode64()
    |> String.replace("=", "")
    ":" <> hash
  end

  def __hash_link__(namespace, name) do
    [namespace, 0, 0, 0, 0, name]
    |> __hash__()
  end
end
