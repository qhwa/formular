code = """
  squares = %{3 => 9, 4 => 16, 5 => 25}
  squares[3]
"""

ast = Code.string_to_quoted!(code)

Benchee.run(%{
  eval: fn -> {:ok, 9} = Formular.eval(code, []) end,
  eval_ast: fn -> {:ok, 9} = Formular.eval(ast, []) end,
  elixir_code_eval: fn -> {9, _} = Code.eval_string(code) end,
  elixir_code_eval_ast: fn -> {9, _} = Code.eval_quoted(ast) end
})
