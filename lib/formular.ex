defmodule Formular do
  @moduledoc """
  A formula evalutator.
  """

  @kernel_functions [
    {:!=, 2},
    {:!==, 2},
    {:+, 1},
    {:+, 2},
    {:-, 1},
    {:-, 2},
    {:*, 2},
    {:/, 2},
    {:|>, 2},
    {:>, 2},
    {:<, 2},
    {:>=, 2},
    {:<=, 2},
    {:==, 2},
    {:abs, 1},
    {:and, 2},
    {:ceil, 1},
    {:div, 2},
    {:floor, 1},
    {:hd, 1},
    {:in, 2},
    {:length, 1},
    {:map_size, 1},
    {:not, 1},
    {:or, 2},
    {:rem, 2},
    {:round, 1},
    {:tl, 1},
    {:trunc, 1},
    {:tuple_size, 1},
    {:!, 1},
    {:&&, 2},
    {:++, 2},
    {:--, 2},
    {:<>, 2},
    {:=~, 2},
    {:||, 2},
    get_in: 2,
    if: 2,
    max: 2,
    min: 2,
    unless: 2,
    sigil_C: 2,
    sigil_D: 2,
    sigil_N: 2,
    sigil_R: 2,
    sigil_S: 2,
    sigil_T: 2,
    sigil_U: 2,
    sigil_W: 2,
    sigil_c: 2,
    sigil_r: 2,
    sigil_s: 2,
    sigil_w: 2,
    to_string: 1
  ]

  @default_eval_options [context: nil]

  @doc """
  Evaluate the expression with binding context.

  ## Example

  ```elixir
  iex> Formular.eval("1", [])
  {:ok, 1}

  iex> Formular.eval(~s["some text"], [])
  {:ok, "some text"}

  iex> Formular.eval("min(5, 100)", [])
  {:ok, 5}

  iex> Formular.eval("max(5, 100)", [])
  {:ok, 100}

  iex> Formular.eval("count * 5", [count: 6])
  {:ok, 30}

  iex> Formular.eval("add.(1, 2)", [add: &(&1 + &2)])
  {:ok, 3}

  iex> Formular.eval("Map.new", [])
  {:error, :called_module_function}

  iex> Formular.eval("Enum.count([1])", [])
  {:error, :called_module_function}

  iex> Formular.eval("min(0, :os.system_time())", [])
  {:error, :called_module_function}

  iex> Formular.eval("inspect.(System.A)", [inspect: &Kernel.inspect/1])
  {:ok, "System.A"}
  ```
  """

  def eval(text, binding, opts \\ @default_eval_options) do
    with {:ok, ast} <- Code.string_to_quoted(text),
         :ok <- valid?(ast) do
      {ret, _} =
        ast
        |> with_context(opts[:context])
        |> Code.eval_quoted(binding)

      {:ok, ret}
    end
  end

  defp valid?(ast) do
    # credo:disable-for-next-line 
    cond do
      contains_module_dot?(ast) ->
        {:error, :called_module_function}

      true ->
        :ok
    end
  end

  def contains_module_dot?({:., _pos, [callee, func]}) when is_atom(func),
    do: module?(callee)

  def contains_module_dot?({op, _pos, args}),
    do: contains_module_dot?(op) or contains_module_dot?(args)

  def contains_module_dot?([]),
    do: false

  def contains_module_dot?([ast | rest]),
    do: contains_module_dot?(ast) or contains_module_dot?(rest)

  def contains_module_dot?(_),
    do: false

  defp module?({:__aliases__, _pos, _}), do: true
  defp module?(mod) when is_atom(mod), do: true
  defp module?(_), do: false

  defp with_context(ast, nil) do
    quote do
      import Kernel, only: unquote(@kernel_functions)

      unquote(ast)
    end
  end

  defp with_context(ast, context) do
    quote do
      import Kernel, only: unquote(@kernel_functions)
      import unquote(context)

      unquote(ast)
    end
  end
end
