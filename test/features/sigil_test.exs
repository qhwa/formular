defmodule SigilTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "with `~w`" do
    code = """
      ~w[a b c]
    """

    assert eval(code, []) == {:ok, ~w[a b c]}
  end
end
