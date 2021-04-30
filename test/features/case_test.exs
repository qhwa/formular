defmodule CaseTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "with `case`" do
    code = """
      case params do
        %{user_name: "Alex"} ->
          "Hello, Alex!"

        _ ->
          "Hello!"
      end
    """

    assert eval(code, params: nil) == {:ok, "Hello!"}
    assert eval(code, params: %{user_name: "Alex"}) == {:ok, "Hello, Alex!"}
  end
end
