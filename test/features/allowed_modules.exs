defmodule AllowedModulesTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  describe "Directly calling module functions" do
    test "works" do
      code = """
        Enum.sort([3, 2, 1])
      """

      assert eval(code, [], allow_modules: [Enum]) == {:ok, [1, 2, 3]}
    end

    test "works with Erlang modules" do
      code = """
      min(0, :os.system_time())
      """

      assert eval(code, [], allow_modules: [:os]) == {:ok, 0}
    end

    test "works with expression" do
      code = """
      m = Enum
      m.count([])
      """

      assert eval(code, [], allow_modules: [Enum]) == {:ok, 0}
    end
  end

  describe "Importing allowed modules" do
    test "works" do
      code = """
        import Enum
        sort([3, 2, 1])
      """

      assert eval(code, [], allow_modules: [Enum]) == {:ok, [1, 2, 3]}
    end

    test "works with `except` opts" do
      code = """
        import Enum, except: [sort: 2]
        sort([3, 2, 1])
      """

      assert eval(code, [], allow_modules: [Enum]) == {:ok, [1, 2, 3]}
    end

    test "works with `except` option and returns error" do
      code = """
        import Enum, except: [sort: 1]
        sort([3, 2, 1])
      """

      assert {:error, %CompileError{}} = eval(code, [], allow_modules: [Enum])
    end
  end

  describe "Allowed modules for requiring" do
    test "works" do
      code = """
        require Logger
        Logger.debug("hi")
      """

      assert eval(code, [], allow_modules: [Logger]) == {:ok, :ok}
    end
  end
end
