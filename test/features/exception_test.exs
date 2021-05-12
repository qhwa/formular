defmodule ExceptionTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "disallowing `raise`" do
    code = """
    raise "test"
    """

    assert eval(code, []) ==
             {:error,
              %CompileError{description: "undefined function raise/1", file: "nofile", line: 1}}
  end

  test "disallowing `throw`" do
    code = """
    throw "test"
    """

    assert eval(code, []) ==
             {:error,
              %CompileError{description: "undefined function throw/1", file: "nofile", line: 1}}
  end
end
