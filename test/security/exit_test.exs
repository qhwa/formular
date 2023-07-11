defmodule ExitTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "disallowing `exit`" do
    code = """
    exit("test")
    """

    assert {:error, %CompileError{description: _, file: "nofile"}} =
             eval(code, [])
  end
end
