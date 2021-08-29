defmodule TimeoutTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "it kills the evaluating process after a given time" do
    sleep = fn ->
      :timer.sleep(:infinity)
    end

    assert eval("sleep.()", [sleep: sleep], timeout: 10) ==
             {:error, :timeout}
  end
end
