code = """
for n <- args do
  case n do
    _ when is_integer(n) ->
      n * n

    _ ->
      n
  end
end
"""

defmodule Compiled do
  def eval(binding) do
    for n <- binding[:args] do
      case n do
        _ when is_integer(n) ->
          n * n

        _ ->
          n
      end
    end
  end
end

f = fn binding ->
  for n <- binding[:args] do
    case n do
      _ when is_integer(n) ->
        n * n

      _ ->
        n
    end
  end
end

ast = Code.string_to_quoted!(code)
mod = Formular.compile_to_module!(code, :test_module)

Benchee.run(%{
  eval: fn -> {:ok, [9]} = Formular.eval(code, args: [3]) end,
  eval_ast: fn -> {:ok, [9]} = Formular.eval(ast, args: [3]) end,
  compiled_module: fn -> {:ok, [9]} = Formular.eval(mod, args: [3]) end,
  elixir_code_eval: fn -> {[9], _} = Code.eval_string(code, args: [3]) end,
  elixir_code_eval_ast: fn -> {[9], _} = Code.eval_quoted(ast, args: [3]) end,
  elixir_compiled_module: fn -> [9] = Compiled.eval(args: [3]) end,
  elixir_compiled_function: fn -> [9] = f.(args: [3]) end
})
