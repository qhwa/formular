defmodule Formular.Compiler do
  @moduledoc """
  This module is used to compile the code into Elixir modules.
  """

  @temp_module Module.concat(__MODULE__, TempModule)

  @doc """
  Create an Elixir module from the raw code (AST).

  The created module will have to public functions:

  - `run/1` which accepts a binding keyword list and execute the code.
  - `used_variables/0` which returns a list of variable names that have
    been used in the code.

  ## Usage

  ```elixir
  iex> ast = quote do: a + b
  ...> Formular.Compiler.create_module(MyMod, ast)
  ...> MyMod.run(a: 1, b: 2)
  3

  ...> MyMod.used_variables()
  [:a, :b]
  ```
  """
  @spec create_module(module(), Macro.t(), Macro.Env.t()) :: {:module, module()}
  def create_module(module, raw_ast, env \\ %Macro.Env{}) do
    Module.create(
      module,
      mod_body(raw_ast, env),
      env
    )

    {:module, module}
  end

  defp mod_body(raw_ast, env) do
    unbound_vars = extract_vars(raw_ast, env)

    quote do
      unquote(importing(env))
      unquote(def_run(raw_ast, unbound_vars))
    end
  end

  defp importing(%{functions: functions, macros: macros}) do
    default = [{Kernel, [def: 2]}]
    merge_f = fn _, a, b -> a ++ b end

    imports =
      default
      |> Keyword.merge(functions, merge_f)
      |> Keyword.merge(macros, merge_f)

    for {mod, fun_list} <- imports do
      quote do
        import unquote(mod), only: unquote(fun_list)
      end
    end
  end

  defp def_run(ast, args) do
    quote do
      def run(binding) do
        unquote(def_args(args))
        unquote(ast |> set_hygiene(__MODULE__))
      end
    end
  end

  defp def_args(args) do
    for arg <- args do
      quote do
        unquote(Macro.var(arg, __MODULE__)) = Keyword.fetch!(binding, unquote(arg))
      end
    end
  end

  @doc false
  def extract_vars(ast, env \\ %Macro.Env{}, vars \\ MapSet.new())

  def extract_vars(ast, env, vars) do
    mod_body =
      quote do
        unquote(importing(env))
        unquote(def_run(ast, vars))
      end

    try do
      Module.create(
        @temp_module,
        mod_body,
        env
      )

      MapSet.to_list(vars)
    rescue
      err in CompileError ->
        with %CompileError{description: err_msg} <- err,
             {:ok, var} <- unbound_var_from_err_msg(err_msg),
             false <- MapSet.member?(vars, var) do
          extract_vars(ast, env, MapSet.put(vars, var))
        else
          _ -> reraise(err, __STACKTRACE__)
        end
    end
  end

  defp unbound_var_from_err_msg(err_msg) do
    reg = ~r/undefined (function|variable) \^?(?<var>\w+)/

    case Regex.named_captures(reg, err_msg) do
      %{"var" => name} ->
        {:ok, String.to_atom(name)}

      _ ->
        :error
    end
  end

  defp set_hygiene(ast, hygiene_context) do
    Macro.postwalk(ast, fn
      {var, meta, context} when is_atom(var) and is_atom(context) ->
        {var, meta, hygiene_context}

      other ->
        other
    end)
  end
end
