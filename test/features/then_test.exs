defmodule ThenTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "then" do
    assert eval(":a |> then(&to_string/1)", []) in [
             {:ok, "a"},
             {:error,
              %CompileError{description: "undefined function then/2", file: "nofile", line: 1}}
           ]
  end
end
