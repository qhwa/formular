defmodule TestContext do
  def foo() do
    42
  end

  def my_div(a, b) do
    div(a, b)
  end

  def no_more_than(a, b) do
    min(a, b)
  end
end

defmodule FormularTest do
  use ExUnit.Case
  doctest Formular

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "evaluating" do
    assert eval("a + b", a: 1, b: -1) == {:ok, 0}

    assert eval("1 + add(foo, 5)", add: &(&1 + &2)) ==
             {:error, :undefined_function, {:foo, 0}}
  end

  test "argument error" do
    assert eval("x(1, 2)", x: 42) == {:error, :argument_error, :x}
  end

  test "with custom context" do
    assert eval("1 + foo", [], context: TestContext) == {:ok, 43}
    assert eval("1 + my_div(foo, 2)", [], context: TestContext) == {:ok, 22}
  end

  test "with pipe" do
    assert eval("100 |> no_more_than(10)", [], context: TestContext) == {:ok, 10}
  end

  test "multiple lines" do
    f = """
      100
      |> no_more_than(10)
    """

    assert eval(f, [], context: TestContext) == {:ok, 10}
  end
end
