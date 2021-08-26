defmodule NoImportingTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "it returns error when importing" do
    assert eval("import Kernel", []) == {:error, :no_import_or_require}
  end

  test "it returns error when requiring" do
    assert eval("require Logger", []) == {:error, :no_import_or_require}
  end
end
