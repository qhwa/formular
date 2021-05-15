defmodule ErrorHandlingTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "it works with runtime error" do
    code = "1 / 0"

    assert eval(code, params: nil) ==
             {:error, %ArithmeticError{message: "bad argument in arithmetic expression"}}
  end
end
