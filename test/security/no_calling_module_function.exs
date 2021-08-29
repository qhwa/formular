defmodule NoCallingModuleFunctionTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "it returns error when calling module function" do
    assert eval("Kernel.exit(:normal)", []) == {:error, :no_calling_module_function}
  end

  test "it returns error when trying to extract module function" do
    assert eval("&Kernel.exit/1", []) == {:error, :no_calling_module_function}
  end
end
