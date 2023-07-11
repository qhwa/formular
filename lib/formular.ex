defmodule Formular do
  require Logger

  @kernel_functions Formular.DefaultFunctions.kernel_functions()
  @kernel_macros Formular.DefaultFunctions.kernel_macros()
  @default_eval_options []
  @default_max_heap_size :infinity
  @default_timeout :infinity

  @moduledoc """
  A tiny extendable DSL evaluator. It's a wrap around Elixir's `Code.eval_string/3` or `Code.eval_quoted/3`, with the following limitations:

  - No calling module functions;
  - No calling some functions which can cause VM to exit;
  - No sending messages;
  - (optional) memory usage limit;
  - (optional) execution time limit.

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

  ## Literals

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

  # keyword list
  iex> Formular.eval("[a: 1, b: :hi]", [])
  {:ok, [a: 1, b: :hi]}
  ```

  ## Variables

  Variables can be passed within the `binding` parameter.

  ```elixir
  # bound value
  iex> Formular.eval("1 + foo", [foo: 42])
  {:ok, 43}
  ```

  ## Functions in the code

  ### Kernel functions and macros

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

  ### Custom functions

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

  unless you explicitly allow it via `allow_modules` option, as shown below:

  ```elixir
  iex> Formular.eval("Map.new([])", [], allow_modules: [Map])
  {:ok, %{}}
  ```

  ## Evaluating AST instead of plain string code

  You may want to use AST instead of string for performance consideration. In this case, an AST can be passed to `eval/3`:

  ```elixir
  iex> "a = b = 10; a * b" |> Code.string_to_quoted!() |> Formular.eval([])
  {:ok, 100}
  ```

  ...so that you don't have to parse it every time before evaluating it.

  ## Compiling the code into an Elixir module

  Most of the likelihood `Code.eval_*` functions are fast enough for your application. However, compiling to an Elixir module will significantly improve the performance. 

  Code can be compiled into an Elixir module via `Formular.compile_to_module!/3` function, as the following:

  ```elixir
  iex> code = quote do: min(a, b)
  ...> compiled = Formular.compile_to_module!(code, MyCompiledMod)
  {:module, MyCompiledMod}
  ...> Formular.eval(compiled, [a: 5, b: 15], timeout: 5_000)
  {:ok, 5}
  ```

  Alternatively, you can directly call `MyCompiledMod.run(a: 5, b: 15)`
  when none limitation of CPU or memory will apply.

  ## Limiting execution time

  The execution time can be limited with the `:timeout` option:

  ```elixir
  iex> sleep = fn -> :timer.sleep(:infinity) end
  ...> Formular.eval("sleep.()", [sleep: sleep], timeout: 10)
  {:error, :timeout}
  ```

  Default timeout is 5_000 milliseconds.

  ## Limiting heap usage

  The evaluation can also be limited in heap size, with `:max_heap_size` option. When the limit is exceeded, an error `{:error, :killed}` will be returned.

  Example:

  ```elixir
  iex> code = "for a <- 0..999_999_999_999, do: to_string(a)"
  ...> Formular.eval(code, [], timeout: :infinity, max_heap_size: 1_000)
  {:error, :killed}
  ```

  The default max heap size is 1_000_000 words.
  """

  @supervisor Formular.Tasks

  @type code :: binary() | Macro.t() | {:module, module()}
  @type option ::
          {:context, module()}
          | {:allow_modules, [module()]}
          | {:max_heap_size, non_neg_integer() | :infinity}
          | {:timeout, non_neg_integer() | :infinity}

  @type options :: [option()]
  @type eval_result :: {:ok, term()} | {:error, term()}

  @doc """
  Evaluate the code with binding context.

  ## Parameters

  - `code` : code to eval. Could be a binary, or parsed AST.
  - `binding` : the variable binding to support the evaluation
  - `options` : current these options are supported:
    - `context` : The modules to import before evaluation.
    - `allow_modules` : The modules allowed to use in the code.
    - `timeout` : A timer used to terminate the evaluation after x milliseconds. `#{@default_timeout}` milliseconds by default.
    - `max_heap_size` : A limit on heap memory usage. If set to zero, the max heap size limit is disabled. `#{@default_max_heap_size}` words by default.

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

  def eval({:module, mod}, binding, opts),
    do: spawn_and_exec(fn -> {:ok, mod.run(binding)} end, opts)

  def eval(text, binding, opts) when is_binary(text) do
    with {:ok, ast} <- Code.string_to_quoted(text) do
      eval_ast(ast, binding, opts)
    end
  end

  def eval(ast, binding, opts),
    do: eval_ast(ast, binding, opts)

  defp eval_ast(ast, binding, opts) do
    with :ok <- valid?(ast, opts) do
      spawn_and_exec(
        fn -> do_eval(ast, binding, opts[:context]) end,
        opts
      )
    end
  end

  defp spawn_and_exec(fun, opts) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    max_heap_size = Keyword.get(opts, :max_heap_size, @default_max_heap_size)

    case {timeout, max_heap_size} do
      {:infinity, :infinity} ->
        fun.()

      _ ->
        {pid, ref} = spawn_task(fun, max_heap_size)

        receive do
          {:result, ret} ->
            Process.demonitor(ref, [:flush])
            ret

          {:DOWN, ^ref, :process, ^pid, reason} ->
            Logger.error("Evaluating process killed, reason: #{inspect(reason)}")
            {:error, :killed}
        after
          timeout ->
            Process.demonitor(ref, [:flush])
            :ok = Task.Supervisor.terminate_child(@supervisor, pid)
            {:error, :timeout}
        end
    end
  end

  defp spawn_task(fun, max_heap_size) do
    parent = self()

    {:ok, pid} =
      Task.Supervisor.start_child(
        @supervisor,
        fn ->
          if max_heap_size != :infinity do
            Process.flag(:max_heap_size, max_heap_size)
          end

          ret = fun.()
          send(parent, {:result, ret})
        end
      )

    ref = Process.monitor(pid)
    {pid, ref}
  end

  defp do_eval(ast, binding, context) do
    {ret, _binding} =
      ast
      |> Code.eval_quoted(
        binding,
        functions: imported_functions(context),
        macros: imported_macros(context),
        requires: [Elixir.Kernel]
      )

    {:ok, ret}
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

  defp valid?(ast, opts) do
    # credo:disable-for-next-line
    case check_rules(ast, opts) do
      false ->
        :ok

      ret ->
        {:error, ret}
    end
  end

  defp check_rules({:., _pos, [Access, :get]}, _),
    do: false

  defp check_rules({:., _pos, [{:__aliases__, _, [mod]}, func]}, opts) when is_atom(func) do
    allow_modules = Keyword.get(opts, :allow_modules, [])

    if Enum.member?(allow_modules, expand_alias(mod)) do
      false
    else
      :no_calling_module_function
    end
  end

  defp check_rules({:., _pos, [_mod, func]}, _opts) when is_atom(func) do
    :no_calling_module_function
  end

  defp check_rules({import_or_require, _pos, [{:__aliases__, _, [mod]} | _]}, opts)
       when import_or_require in [:import, :require] do
    allow_modules = Keyword.get(opts, :allow_modules, [])

    if Enum.member?(allow_modules, expand_alias(mod)) do
      false
    else
      :no_import_or_require
    end
  end

  defp check_rules({import_or_require, _pos, [_ | _]}, _opts)
       when import_or_require in [:import, :require] do
    :no_import_or_require
  end

  defp check_rules({op, _pos, args}, opts),
    do: check_rules(op, opts) || check_rules(args, opts)

  defp check_rules([], _),
    do: false

  defp check_rules([ast | rest], opts),
    do: check_rules(ast, opts) || check_rules(rest, opts)

  defp check_rules(_, _opts),
    do: false

  defp expand_alias(mod) when is_atom(mod),
    do: Module.concat(:"Elixir", mod)

  @doc """
  Compile the code into an Elixir module function.
  """
  @spec compile_to_module!(code(), module(), module() | options()) :: {:module, module()}
  def compile_to_module!(code, mod, opts \\ [])

  def compile_to_module!(code, mode, context) when is_atom(context),
    do: compile_to_module!(code, mode, context: context)

  def compile_to_module!(code, mod, opts) when is_binary(code) and is_list(opts),
    do:
      code
      |> Code.string_to_quoted!()
      |> compile_ast_to_module!(mod, opts)

  def compile_to_module!(ast, mod, opts),
    do: compile_ast_to_module!(ast, mod, opts)

  defp compile_ast_to_module!(ast, mod, opts) do
    with :ok <- valid?(ast, opts) do
      env = %Macro.Env{
        context_modules: opts[:allow_modules],
        functions: imported_functions(opts[:context]),
        macros: imported_macros(opts[:context]),
        requires: [Elixir.Kernel]
      }

      Formular.Compiler.create_module(mod, ast, env)
    end
  end

  @doc """
  Returns used variables in the code. This can be helpful if
  you intend to build some UI based on the variables, or to
  validate if the code is using variables within the allowed
  list.

  ## Example

  ```elixir
  iex> code = "f.(a + b)"
  ...> Formular.used_vars(code) |> Enum.sort()
  [:a, :b, :f]
  ```
  """
  @spec used_vars(code()) :: [atom()]
  def used_vars(code) when is_binary(code),
    do: code |> Code.string_to_quoted!() |> used_vars()

  def used_vars(code),
    do: Formular.Compiler.extract_vars(code)
end
