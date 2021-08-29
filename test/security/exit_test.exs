defmodule ExitTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "disallowing `exit`" do
    code = """
    exit("test")
    """

    assert eval(code, []) ==
             {:error,
              %CompileError{description: "undefined function exit/1", file: "nofile", line: 1}}
  end
end
