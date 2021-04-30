defmodule IfTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "with `if`" do
    code = """
      if n > 0 do
        1
      else
        -1
      end
    """

    assert eval(code, n: 100) == {:ok, 1}
    assert eval(code, n: -10) == {:ok, -1}
  end
end
