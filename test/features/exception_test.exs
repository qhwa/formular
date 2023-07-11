defmodule ExceptionTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "disallowing `raise`" do
    code = """
    raise "test"
    """

    assert_compile_error(code)
  end

  test "disallowing `throw`" do
    code = """
    throw "test"
    """

    assert_compile_error(code)
  end

  defp assert_compile_error(code) do
    assert {:error, %CompileError{file: "nofile"}} = eval(code, [])
  end
end
