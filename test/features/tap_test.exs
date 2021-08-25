defmodule TapTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "tap" do
    run = fn ->
      eval("~s'100' |> tap(&puts/1)", [], context: IO)
    end

    assert run.() in [
             {:ok, "100"},
             {:error,
              %CompileError{description: "undefined function tap/2", file: "nofile", line: 1}}
           ]
  end
end
