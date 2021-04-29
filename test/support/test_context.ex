defmodule Formular.TestContext do
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
