defmodule CustomMacroTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "with custom macro" do
    defmodule Context do
      defmacro hello do
        quote do
          unquote("hi")
        end
      end
    end

    code = """
    hello()
    """

    assert eval(code, [], context: Context) == {:ok, "hi"}
  end
end
