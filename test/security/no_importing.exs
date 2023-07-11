defmodule NoImportingTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "it returns error when importing" do
    assert eval("import Kernel", []) == {:error, :no_import_or_require}
  end

  test "it returns error when requiring" do
    assert eval("require Logger", []) == {:error, :no_import_or_require}
  end

  test "it is ok to require when is specifically set as allowed" do
    assert eval("require Logger\n:ok", [], allow_modules: [Logger]) == {:ok, :ok}
  end

  test "it is ok to import when is specifically set as allowed" do
    assert eval("import Logger\n:ok", [], allow_modules: [Logger]) == {:ok, :ok}
  end

  test "requiring returns error when not specifically set as allowed" do
    assert eval("require Logger\n:ok", [], allow_modules: [:logger]) ==
             {:error, :no_import_or_require}
  end

  test "importing returns error when not specifically set as allowed" do
    assert eval("import Logger\n:ok", [], allow_modules: [:logger]) ==
             {:error, :no_import_or_require}
  end
end
