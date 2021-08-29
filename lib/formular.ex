defmodule Formular do
  @kernel_functions Formular.DefaultFunctions.kernel_functions()
  @kernel_macros Formular.DefaultFunctions.kernel_macros()

  @moduledoc """
  A simple extendable DSL evaluator. It's a limited version of `Code.eval_string/3` or `Code.eval_quoted/3`.

  So far, the limitations are:

  - No calling module functions;
  - No calling some functions which can cause VM to exit;
  - No sending messages.

  Here's an example using this module to evaluate a discount number against an order struct:

  ```elixir
  iex> discount_formula = ~s"
  ...>   case order do
  ...>     # old books get a big promotion
  ...>     %{book: %{year: year}} when year < 2000 ->
  ...>       0.5
  ...>   
  ...>     %{book: %{tags: tags}} ->
  ...>       # Elixir books!
  ...>       if ~s{elixir} in tags do
  ...>         0.9
  ...>       else
  ...>         1.0
  ...>       end
  ...>
  ...>     _ ->
  ...>       1.0
  ...>   end
  ...> "
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

  #### Kernel functions and macros

  Kernel functions and macros are limitedly supported. Only a picked list of them are supported out of the box so that dangerouse functions such as `Kernel.exit/1` will not be invoked.

  Supported functions from `Kernel` are:

  ```elixir
  #{inspect(@kernel_functions, pretty: true)}
  ```

  Supported macros from `Kernel` are:

  ```elixir
  #{inspect(@kernel_macros, pretty: true)}
  ```

  Example:

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
        |> Code.eval_quoted(
          binding,
          functions: imported_functions(opts[:context]),
          macros: imported_macros(opts[:context]),
          requires: [Elixir.Kernel]
        )

      {:ok, ret}
    end
  rescue
    err ->
      {:error, err}
  end

  defp imported_functions(nil),
    do: [{Elixir.Kernel, @kernel_functions}]

  defp imported_functions(mod) when is_atom(mod),
    do: [
      {mod, mod.__info__(:functions)},
      {Elixir.Kernel, @kernel_functions}
    ]

  defp imported_macros(nil),
    do: [{Elixir.Kernel, @kernel_macros}]

  defp imported_macros(mod) when is_atom(mod),
    do: [
      {mod, mod.__info__(:macros)},
      {Elixir.Kernel, @kernel_macros}
    ]

  defp valid?(ast) do
    # credo:disable-for-next-line
    case check_rules(ast) do
      false ->
        :ok

      ret ->
        {:error, ret}
    end
  end

  defp check_rules({:., _pos, [_callee, func]}) when is_atom(func),
    do: :no_calling_module_function

  defp check_rules({:import, _pos, [_ | _]}),
    do: :no_import_or_require

  defp check_rules({:require, _pos, [_]}),
    do: :no_import_or_require

  defp check_rules({op, _pos, args}),
    do: check_rules(op) || check_rules(args)

  defp check_rules([]),
    do: false

  defp check_rules([ast | rest]),
    do: check_rules(ast) || check_rules(rest)

  defp check_rules(_),
    do: false
end
