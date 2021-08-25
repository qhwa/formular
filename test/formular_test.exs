defmodule FormularTest do
  use ExUnit.Case
  doctest Formular

  alias Formular.TestContext

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "evaluating" do
    assert eval("a + b", a: 1, b: -1) == {:ok, 0}
  end

  test "argument error" do
    assert {:error, %CompileError{}} = eval("x(1, 2)", x: 42)
  end

  test "with custom context" do
    assert eval("1 + foo()", [], context: TestContext) == {:ok, 43}
    assert eval("1 + my_div(foo(), 2)", [], context: TestContext) == {:ok, 22}
  end

  test "multiple lines" do
    f = """
      100
      |> no_more_than(10)
    """

    assert eval(f, [], context: TestContext) == {:ok, 10}
  end

  test "with `if`" do
    f = """
      a = 10
      if a >= 5 do
        "GTE"
      else
        "LT"
      end
    """

    assert eval(f, []) == {:ok, "GTE"}
  end

  test "defining a function" do
    f = """
      a = fn ->
        :foo
      end

      a.()
    """

    assert eval(f, []) == {:ok, :foo}
  end

  test "calling a module function in a newly defined function will not work" do
    f = """
      a = fn ->
        :os.system_time()
      end

      a.()
    """

    assert eval(f, []) == {:error, :no_calling_module_function}
  end
end
