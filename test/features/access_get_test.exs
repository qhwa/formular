defmodule AccessGetTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "with `Access.get/2`" do
    code = """
      params[:foo]
    """

    assert eval(code, params: %{}) == {:ok, nil}
    assert eval(code, params: %{foo: "bar"}) == {:ok, "bar"}
  end
end
