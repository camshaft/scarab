defmodule Scarab.Backend.FS do
  @behaviour Scarab.Backend

  def put(hash, content, %{path: path}) do
    path
    |> resolve_hash(hash)
    |> mkdir()
    |> File.write(content)
  end

  def get(hash, %{path: path}) do
    path
    |> resolve_hash(hash)
    |> File.read()
  end

  def link(from, to, config) do
    put(from, to, config)
  end

  def delete(hash, %{path: path}) do
    path = resolve_hash(path, hash)
    case File.rm(path) do
      res when res in [:ok, {:error, :enoent}, {:error, :enotdir}] ->
        :ok
      error ->
        error
    end
  end

  defp resolve_hash(path, <<first :: binary-size(2), second :: binary-size(2), rest :: binary>>) do
    Path.join([path, first, second, rest])
  end

  defp mkdir(target) do
    target
    |> Path.dirname()
    |> File.mkdir_p!()
    target
  end
end
