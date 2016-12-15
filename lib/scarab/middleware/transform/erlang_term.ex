defmodule Scarab.Middleware.Transform.ErlangTerm do
  defmacro __using__(opts) do
    quote do
      defoverridable [put: 1, get: 1]
      def put(content) do
        content
        |> :erlang.term_to_binary(unquote(opts))
        |> super()
      end

      def get(hash) do
        case super(hash) do
          {:ok, bin} ->
            {:ok, :erlang.binary_to_term(bin)}
          error ->
            error
        end
      end
    end
  end
end
