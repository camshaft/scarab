defmodule Scarab do
  defmacro __using__(opts) do
    backend = opts[:backend]
    config = opts[:config]

    quote do
      def put(content) do
        Scarab.put(unquote(backend), content, unquote(config))
      end

      def get(hash) do
        Scarab.get(unquote(backend), hash, unquote(config))
      end

      def resolve(namespace, ref) do
        Scarab.resolve(unquote(backend), namespace, ref, unquote(config))
      end

      def link(namespace, name, ref) do
        Scarab.link(unquote(backend), namespace, name, ref, unquote(config))
      end

      def unlink(namespace, name) do
        Scarab.unlink(unquote(backend), namespace, name, unquote(config))
      end

      def valid_link?(":" <> _), do: false
      def valid_tag(_), do: true
    end
  end

  def put(backend, content, config) do
    hash = hash(content)
    case put(backend, hash, content, config) do
      :ok ->
        {:ok, hash}
      error ->
        error
    end
  end

  defp put(backend, ":" <> hash, content, config) do
    backend.put(hash, content, config)
  end

  def get(backend, ":" <> hash, config) do
    backend.get(hash, config)
  end

  def resolve(backend, _, ":" <> _ = hash, config) do
    get(backend, hash, config)
  end
  def resolve(backend, namespace, name, config) when is_binary(name) do
    hash = hash_link(namespace, name)
    case get(backend, hash, config) do
      {:ok, ref} ->
        resolve(backend, namespace, ref, config)
      error ->
        error
    end
  end
  def resolve(_, _, name, _) do
    name
  end

  def link(_, _, ":" <> _ = name, _, _) do
    {:error, {:invalid_tag, name}}
  end
  def link(backend, namespace, name, ref, config) do
    ":" <> hash = hash_link(namespace, name)
    backend.link(hash, ref, config)
  end

  def unlink(backend, namespace, name, config) do
    ":" <> hash = hash_link(namespace, name)
    backend.delete(hash, config)
  end

  defp hash(content) do
    hash = :crypto.hash(:sha, content)
    |> Base.url_encode64()
    |> String.replace("=", "")
    ":" <> hash
  end

  def hash_link(namespace, name) do
    [namespace, 0, 0, 0, 0, name]
    |> hash()
  end
end
