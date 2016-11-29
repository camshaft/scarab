defmodule Scarab.Backend.S3 do
  @behaviour Scarab.Backend

  def put(hash, content, config) do
    hash
    |> resolve_hash()
    |> _put(content, config, [
      cache_control: "public, max-age=31536000"
    ])
  end

  def get(hash, config) do
    hash
    |> resolve_hash()
    |> _get(config)
  end

  def link(from, to, config) do
    link_max_age = config[:link_max_age] || 60

    from
    |> resolve_hash()
    |> _put(to, config, [
      cache_control: "public, max-age=#{link_max_age}"
    ])
  end

  def delete(obj, %{bucket: bucket} = config) do
    client = config[:client] || ExAws.S3
    obj = resolve_hash(obj)
    case request(client.delete_object(bucket, obj)) do
      {:ok, %{status_code: code}} when code in [200, 204] ->
        :ok
      error ->
        error
    end
  end

  defp _get(obj, %{bucket: bucket} = config) do
    client = config[:client] || ExAws.S3
    case request(client.get_object(bucket, obj)) do
      {:ok, %{body: body, status_code: 200}} ->
        {:ok, body}
      {:ok, %{status_code: 404}} ->
        {:error, :enoent}
      {:error, {:http_error, 404, _}} ->
        {:error, :enoent}
      error ->
        error
    end
  end

  defp _put(obj, content, %{bucket: bucket} = config, opts) do
    client = config[:client] || ExAws.S3
    case request(client.put_object(bucket, obj, content, opts)) do
      {:ok, %{status_code: 200}} ->
        :ok
      error ->
        error
    end
  end

  defp request(req) when is_tuple(req) do
    req
  end
  defp request(req) do
    ExAws.request(req)
  end

  defp resolve_hash(<<first :: binary-size(2), second :: binary-size(2), rest :: binary>>) do
    Path.join([first, second, rest])
  end
end
