defmodule Formular do
  @moduledoc """
  A formular parser
  """

  @kernel_ops ~w[+ - * / min max]a
  @default_eval_options [context: nil]

  @doc """
  Parse a text expression into an Elixir expression.

  ## Examples

      iex> Formular.parse("100")
      {:ok, 100}

      iex> Formular.parse("var")
      {:ok, :var}

      iex> Formular.parse("1 + 2")
      {:ok, [:+, 1, 2]}

      iex> Formular.parse("1 + foo")
      {:ok, [:+, 1, :foo]}

      iex> Formular.parse("(1 + 2) * 5")
      {:ok, [:*, [:+, 1, 2], 5]}

      iex> Formular.parse("lines * 50 + delivery_km * 2")
      {:ok, [:+, [:*, :lines, 50], [:*, :delivery_km, 2]]}

      iex> Formular.parse("min(lines, 10) * 50 + delivery_km * 2")
      {:ok, [:+, [:*, [:min, :lines, 10], 50], [:*, :delivery_km, 2]]}

  """
  def parse(text) do
    with {:ok, parsed} <- Code.string_to_quoted(text) do
      {:ok, transform(parsed)}
    end
  end

  defp transform({:{}, [_ | _], args}),
    do: args |> List.to_tuple()

  defp transform({:|>, _, [first_arg, {f, _, rest_args}]}) do
    [f, first_arg | rest_args]
  end

  defp transform({fun, _, nil}),
    do: fun

  defp transform({op, [_ | _], args}) when is_list(args),
    do: [op | Enum.map(args, &transform/1)]

  defp transform(x), do: x

  @doc """
  Evaluate the expression with binding context.

  ## Example

  ```elixir
  iex> Formular.eval("1", [])
  {:ok, 1}

  iex> Formular.eval(~s["some text"], [])
  {:ok, "some text"}

  iex> Formular.eval("1 + foo", [foo: fn -> 42 end])
  {:ok, 43}

  iex> Formular.eval("1 + add(-1, 5)", [add: &(&1 + &2)])
  {:ok, 5}

  iex> Formular.eval("min(5, 100)", [])
  {:ok, 5}

  iex> Formular.eval("max(5, 100)", [])
  {:ok, 100}

  iex> Formular.eval("count * 5", [count: 6])
  {:ok, 30}

  iex> Formular.eval("10 + undefined", [])
  {:error, :undefined_function, {:undefined, 0}}
  ```
  """

  def eval(text, binding, opts \\ @default_eval_options) do
    with {:ok, code} <- parse(text) do
      eval_code(code, binding, opts)
    end
  end

  defp eval_code(n, _binding, _opts) when is_integer(n) do
    {:ok, n}
  end

  defp eval_code(text, _binding, _opts) when is_binary(text) do
    {:ok, text}
  end

  defp eval_code(fun, binding, opts) when is_atom(fun) do
    eval_code([fun], binding, opts)
  end

  defp eval_code([fun | args], binding, opts) when is_atom(fun) do
    case mfa(fun, args, binding, opts) do
      {:ok, {module, f, args}} ->
        {:ok, apply(module, f, args)}

      {:ok, {f, args}} when is_function(f) ->
        {:ok, apply(f, args)}

      other ->
        other
    end
  end

  defp eval_args([], _binding, _opts) do
    {:ok, []}
  end

  defp eval_args([arg | rest], binding, opts) do
    with {:ok, ret} <- eval_code(arg, binding, opts),
         {:ok, rest_ret} <- eval_args(rest, binding, opts) do
      {:ok, [ret | rest_ret]}
    end
  end

  defp mfa(fun, args, binding, opts) do
    arity = Enum.count(args)

    case Keyword.fetch(binding, fun) do
      {:ok, f} when is_function(f, arity) ->
        with {:ok, args} <- eval_args(args, binding, opts) do
          {:ok, {f, args}}
        end

      {:ok, other} when arity == 0 ->
        {:ok, {fn -> other end, []}}

      {:ok, _} ->
        {:error, :argument_error, fun}

      :error ->
        context = opts[:context]

        cond do
          function_exported?(context, fun, arity) ->
            with {:ok, args} <- eval_args(args, binding, opts) do
              {:ok, {context, fun, args}}
            end

          fun in @kernel_ops ->
            with {:ok, args} <- eval_args(args, binding, opts) do
              {:ok, {Kernel, fun, args}}
            end

          true ->
            {:error, :undefined_function, {fun, arity}}
        end
    end
  end
end
