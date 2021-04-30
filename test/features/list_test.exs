defmodule ListTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "list" do
    code = """
    [1, 2, 3]
    """

    assert eval(code, []) == {:ok, [1, 2, 3]}
  end
end
