defmodule WithTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "with `with`" do
    code = """
      with params do
        %{user_name: "Alex"} ->
          "Hello, Alex!"

        _ ->
          "Hello!"
      end
    """

    assert eval(code, params: nil) == "Hello!"
  end
end
