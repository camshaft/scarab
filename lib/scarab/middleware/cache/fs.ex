defmodule Scarab.Middleware.Cache.FS do
  defmacro __using__(opts) do
    path = opts[:path] || ".scarab"

    quote do
      use Scarab.Middleware.Cache.Base, [
        module: unquote(__MODULE__),
        config: unquote(path),
        link_max_age: unquote(opts[:link_max_age])
      ]
    end
  end

  defp get(path, hash) do
    path
    |> resolve_hash(hash)
    |> File.read()
  end

  defp put(path, hash, contents) do
    path
    |> resolve_hash(hash)
    |> mkdir()
    |> File.write(contents)
  end

  def get_or_put(path, hash, parent) do
    case get(path, hash) do
      {:ok, value} ->
        {:ok, value}
      _ ->
        case parent.(hash) do
          {:ok, bin} ->
            put(path, hash, bin)
            {:ok, bin}
          error ->
            error
        end
    end
  end

  def get_or_put_link(path, hash, ttl, parent) do
    if stale?(path, hash, ttl) do
      purge(path, hash)
    end
    get_or_put(path, hash, parent)
  end

  defp resolve_hash(path, <<":", first :: binary-size(2), second :: binary-size(2), rest :: binary>>) do
    Path.join([path, first, second, rest])
  end

  def mkdir(target) do
    target
    |> Path.dirname()
    |> File.mkdir_p!()
    target
  end

  def purge(path, hash) do
    path
    |> resolve_hash(hash)
    |> File.rm_rf()
  end

  defp stale?(path, hash, ttl) do
    path
    |> resolve_hash(hash)
    |> last_modified()
    |> Kernel.>(System.system_time(:seconds) - div(ttl, :timer.seconds(1)))
  end

  defp last_modified(path) do
    case File.stat(path, [time: :posix]) do
      {:ok, %{mtime: mtime}} ->
        mtime
      {:error, _} ->
        0
    end
  end
end
