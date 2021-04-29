defmodule PipeTest do
  use ExUnit.Case

  alias Formular.TestContext

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "with pipe" do
    assert eval("100 |> no_more_than(10)", [], context: TestContext) == {:ok, 10}
  end
end
