defmodule ExitTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "disallowing `exit`" do
    code = """
    exit("test")
    """

    assert {:error,
            %CompileError{description: "undefined function exit/1" <> _, file: "nofile", line: 1}} =
             eval(code, [])
  end
end
