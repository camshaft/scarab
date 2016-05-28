defmodule Scarab.Backend do
  use Behaviour

  defcallback put(hash :: binary, content :: binary, config :: map) :: :ok | {:error, term}
  defcallback get(hash :: binary, config :: map) :: {:ok, contents :: binary} | {:error, term}
  defcallback link(from :: binary, to :: binary, config :: map) :: :ok | {:error, term}
  defcallback delete(hash :: binary, config :: map) :: :ok | {:error, term}
end
