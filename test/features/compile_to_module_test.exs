defmodule CompileToModuleTest do
  use ExUnit.Case, async: true

  defmodule CompileToModuleTest.ContextModule do
    def foo, do: 42
  end

  describe "compile_to_module!/2" do
    test "it works" do
      code = """
      1 + 5
      """

      mod = FormularModule
      assert {:module, ^mod} = Formular.compile_to_module!(code, mod)
      assert mod.run([]) == 6
    end

    test "it works with bindings" do
      code = """
      1 + foo
      """

      mod = FormularModule2
      assert {:module, ^mod} = Formular.compile_to_module!(code, mod)
      assert mod.run(foo: 42) == 43
    end

    test "it works with context module" do
      code = """
      1 + foo()
      """

      mod = FormularModule3

      assert {:module, ^mod} =
               Formular.compile_to_module!(code, mod, CompileToModuleTest.ContextModule)

      assert mod.run([]) == 43
    end
  end

  describe "kernel functions" do
    test "it works with allowed functions" do
      code = """
      max(1, 2)
      """

      mod = FormularModule4
      assert {:module, ^mod} = Formular.compile_to_module!(code, mod)
      assert mod.run([]) == 2
    end

    test "it fails with disallowed functions" do
      code = """
      exit()
      """

      mod = FormularModule5
      assert_raise CompileError, fn -> Formular.compile_to_module!(code, mod) end
    end
  end

  describe "exmaple code" do
    test "it works" do
      code = """
      for n <- args do
        case n do
          _ when is_integer(n) ->
            n * n

          _ ->
            n
        end
      end
      """

      mod = Formular.compile_to_module!(code, :test_module)
      assert {:ok, [9]} = Formular.eval(mod, args: [3])
    end
  end
end
