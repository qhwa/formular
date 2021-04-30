defmodule InTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "with `in`" do
    code = """
    1 in [1, 2]
    """

    assert eval(code, []) == {:ok, true}
  end
end
