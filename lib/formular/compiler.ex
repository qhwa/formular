defmodule Formular.Compiler do
  @moduledoc """
  This module is used to compile the code into Elixir modules.
  """

  @scope_and_binding_ops ~w[-> def]a
  @scope_ops ~w[for]a
  @binding_ops ~w[<- =]a

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
    quote do
      unquote(importing(env))
      unquote(def_run(raw_ast))
      unquote(def_used_variables(raw_ast))
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

  defp def_run(raw_ast) do
    {ast, args} = inject_vars(raw_ast)

    quote do
      def run(binding) do
        unquote(def_args(args))
        unquote(ast)
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
  def extract_vars(ast),
    do: do_extract_vars(ast) |> MapSet.to_list()

  defp inject_vars(ast) do
    collection = do_extract_vars(ast)

    {
      set_hygiene(ast, __MODULE__),
      MapSet.to_list(collection)
    }
  end

  defp do_extract_vars(ast) do
    initial_vars = {
      _bound_scopes = [MapSet.new([])],
      _collection = MapSet.new([])
    }

    pre = fn
      {:cond, _, [[do: cond_do_bock]]} = ast, acc ->
        acc =
          for {:->, _, [left, _right]} <- cond_do_bock,
              unbind_var <- do_extract_vars(left),
              reduce: acc do
            acc ->
              collect_var_if_unbind(acc, unbind_var)
          end

        {ast, acc}

      {op, _, [left | _]} = ast, acc when op in @scope_and_binding_ops ->
        bound = do_extract_vars(left)
        {ast, acc |> push_scope() |> collect_bound(bound)}

      {op, _, _} = ast, acc when op in @scope_ops ->
        {ast, push_scope(acc)}

      {op, _, [left, _]} = ast, acc when op in @binding_ops ->
        bound = do_extract_vars(left)
        {ast, collect_bound(acc, bound)}

      {:^, _, [{pinned, _, _}]} = ast, acc when is_atom(pinned) ->
        {ast, delete_unbound(acc, pinned)}

      ast, vars ->
        {ast, vars}
    end

    post = fn
      {op, _, _} = ast, acc
      when op in @scope_ops
      when op in @scope_and_binding_ops ->
        {ast, pop_scope(acc)}

      {var, _meta, context} = ast, acc
      when is_atom(var) and is_atom(context) ->
        if defined?(var, acc) do
          {ast, acc}
        else
          {ast, collect_var(acc, var)}
        end

      ast, vars ->
        {ast, vars}
    end

    {^ast, {_, collection}} = Macro.traverse(ast, initial_vars, pre, post)
    collection
  end

  defp push_scope({scopes, collection}),
    do: {[MapSet.new([]) | scopes], collection}

  defp pop_scope({scopes, collection}),
    do: {tl(scopes), collection}

  defp collect_var_if_unbind({scopes, collection}, var) do
    if Enum.all?(scopes, &(var not in &1)) do
      {scopes, MapSet.put(collection, var)}
    else
      {scopes, collection}
    end
  end

  defp collect_var({scopes, collection}, unbind_var),
    do: {scopes, MapSet.put(collection, unbind_var)}

  defp delete_unbound({[scope | tail], collection}, var),
    do: {[MapSet.delete(scope, var) | tail], collection}

  defp collect_bound({[scope | tail], collection}, bounds),
    do: {[MapSet.union(scope, bounds) | tail], collection}

  defp defined?(var, {scopes, _}),
    do: Enum.any?(scopes, &(var in &1))

  defp set_hygiene(ast, hygiene_context) do
    Macro.postwalk(ast, fn
      {var, meta, context} when is_atom(var) and is_atom(context) ->
        {var, meta, hygiene_context}

      other ->
        other
    end)
  end

  defp def_used_variables(raw_ast) do
    vars = extract_vars(raw_ast)

    quote do
      def used_variables do
        [unquote_splicing(vars)]
      end
    end
  end
end
