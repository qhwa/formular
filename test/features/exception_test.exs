defmodule ExceptionTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "disallowing `raise`" do
    code = """
    raise "test"
    """

    assert_compile_error("undefined function raise/1", code)
  end

  test "disallowing `throw`" do
    code = """
    throw "test"
    """

    assert_compile_error("undefined function throw/1", code)
  end

  defp assert_compile_error(error, code) do
    assert {:error, %CompileError{description: err_msg, file: "nofile", line: 1}} = eval(code, [])
    assert err_msg =~ error
  end
end
