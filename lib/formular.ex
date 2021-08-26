defmodule Formular do
  @moduledoc """
  A simple extendable DSL evaluator. It's a limited version of `Code.eval_string/3` or `Code.eval_quoted/3`.

  So far, the limitations are:

  - No calling module functions;
  - No calling some functions which can cause VM to exit;
  - No sending messages.

  Here's an example using this module to evaluate a discount number against an order struct:

  ```elixir
  iex> discount_formula =
  ...> """
  ...>   case order do
  ...>     # old books get a big promotion
  ...>     %{book: %{year: year}} when year < 2000 ->
  ...>       0.5
  ...>   
  ...>     %{book: %{tags: tags}} ->
  ...>       # Elixir books!
  ...>       if "elixir" in tags do
  ...>         0.9
  ...>       else
  ...>         1.0
  ...>       end
  ...>
  ...>     _ ->
  ...>       1.0
  ...>   end
  ...> """
  ...>
  ...> book_order = %{
  ...>   book: %{
  ...>     title: "Elixir in Action", year: 2019, tags: ["elixir"]
  ...>   }
  ...> }
  ...>
  ...> Formular.eval(discount_formula, [order: book_order])
  {:ok, 0.9}
  ```

  The code being evaluated is just a piece of Elixir code, so it can be expressive when describing business rules.

  ## Usage

  ### Simple expressions

  ```elixir
  # number
  iex> Formular.eval("1", [])
  {:ok, 1} # <- note that it's an integer

  # plain string
  iex> Formular.eval(~s["some text"], [])
  {:ok, "some text"}

  # atom
  iex> Formular.eval(":foo", [])
  {:ok, :foo}

  # list
  iex> Formular.eval("[:foo, Bar]", [])
  {:ok, [:foo, Bar]}
  ```

  ### Variables

  Variables can be passed within the `binding` parameter.

  ```elixir
  # bound value
  iex> Formular.eval("1 + foo", [foo: 42])
  {:ok, 43}
  ```

  ### Functions in the code

  #### Kernel functions

  Kernel functions are limitedly supported. Only a picked list of Kernel functions are supported out of the box so that dangerouse functions such as `Kernel.exit/1` will not be invoked.

  Refer to [the code](https://github.com/qhwa/formular/blob/master/lib/formular.ex#L6) for the whole list.

  ```elixir
  # Kernel function
  iex> Formular.eval("min(5, 100)", [])
  {:ok, 5}

  iex> Formular.eval("max(5, 100)", [])
  {:ok, 100}
  ```

  #### Custom functions

  Custom functions can be provided in two ways, either in a binding lambda:

  ```elixir
  # bound function
  iex> Formular.eval("1 + add.(-1, 5)", [add: &(&1 + &2)])
  {:ok, 5}
  ```
  ... or with a context module:

  ```elixir
  iex> defmodule MyContext do
  ...>   def foo() do
  ...>     42
  ...>   end
  ...> end

  ...> Formular.eval("10 + foo", [], context: MyContext)
  {:ok, 52}
  ```

  **Directly calling to module functions in the code are disallowed** for security reason. For example:

  ```elixir
  iex> Formular.eval("Map.new", [])
  {:error, :no_calling_module_function}

  iex> Formular.eval("min(0, :os.system_time())", [])
  {:error, :no_calling_module_function}
  ```

  ### Evaluating AST instead of plain string code

  You may want to use AST instead of string for performance consideration. In this case, an AST can be passed to `eval/3`:

  ```elixir
  iex> "a = b = 10; a * b" |> Code.string_to_quoted!() |> Formular.eval([])
  {:ok, 100}
  ```

  ...so that you don't have to parse it every time before evaluating it.

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
                      {:is_atom, 1},
                      {:is_binary, 1},
                      {:is_bitstring, 1},
                      {:is_boolean, 1},
                      {:is_exception, 1},
                      {:is_exception, 2},
                      {:is_float, 1},
                      {:is_function, 1},
                      {:is_integer, 1},
                      {:is_list, 1},
                      {:is_map, 1},
                      {:is_map_key, 2},
                      {:is_nil, 1},
                      {:is_number, 1},
                      {:is_pid, 1},
                      {:is_port, 1},
                      {:is_reference, 1},
                      {:is_struct, 1},
                      {:is_struct, 2},
                      {:is_tuple, 1},
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
                      tap: 2,
                      to_string: 1,
                      then: 2
                    ]
                    |> Enum.filter(fn {f, arity} ->
                      function_exported?(Kernel, f, arity) or
                        macro_exported?(Kernel, f, arity)
                    end)

  @default_eval_options []

  @type code :: binary() | Macro.t()
  @type option :: {:context, module()}
  @type options :: [option()]
  @type eval_result :: {:ok, term()} | {:error, term()}

  @doc """
  Evaluate the code with binding context.

  ## Parameters

  - `code` : code to eval. Could be a binary, or parsed AST.
  - `binding` : the variable binding to support the evaluation
  - `options` : current these options are supported:
    - `context` : The module to import before evaluation.

  ## Examples

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
  {:error, :no_calling_module_function}

  iex> Formular.eval("Enum.count([1])", [])
  {:error, :no_calling_module_function}

  iex> Formular.eval("min(0, :os.system_time())", [])
  {:error, :no_calling_module_function}

  iex> Formular.eval("inspect.(System.A)", [inspect: &Kernel.inspect/1])
  {:ok, "System.A"}

  iex> Formular.eval "f = &IO.inspect/1", []              
  {:error, :no_calling_module_function}

  iex> Formular.eval("mod = IO; mod.inspect(1)", [])
  {:error, :no_calling_module_function}

  iex> "a = b = 10; a * b" |> Code.string_to_quoted!() |> Formular.eval([])
  {:ok, 100}
  ```
  """

  @spec eval(code, binding :: keyword(), options()) :: eval_result()
  def eval(code, binding, opts \\ @default_eval_options)

  def eval(text, binding, opts) when is_binary(text) do
    with {:ok, ast} <- Code.string_to_quoted(text) do
      eval_ast(ast, binding, opts)
    end
  end

  def eval(ast, binding, opts),
    do: eval_ast(ast, binding, opts)

  defp eval_ast(ast, binding, opts) do
    with :ok <- valid?(ast) do
      {ret, _} =
        ast
        |> with_context(opts[:context])
        |> Code.eval_quoted(binding)

      {:ok, ret}
    end
  rescue
    err ->
      {:error, err}
  end

  defp valid?(ast) do
    # credo:disable-for-next-line
    cond do
      contains_module_dot?(ast) ->
        {:error, :no_calling_module_function}

      true ->
        :ok
    end
  end

  defp contains_module_dot?({:., _pos, [_callee, func]}) when is_atom(func),
    do: true

  defp contains_module_dot?({op, _pos, args}),
    do: contains_module_dot?(op) or contains_module_dot?(args)

  defp contains_module_dot?([]),
    do: false

  defp contains_module_dot?([ast | rest]),
    do: contains_module_dot?(ast) or contains_module_dot?(rest)

  defp contains_module_dot?(_),
    do: false

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
