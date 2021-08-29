defmodule HeapSizeLimitTest do
  use ExUnit.Case

  defdelegate eval(code, binding, opts \\ []), to: Formular

  test "it works atom flooding" do
    code = ~S|for a <- struct(Range, %{first: 0, last: 999_999_999_999, step: 1}), do: :"#{a}"|

    assert eval(code, [], timeout: :infinity, max_heap_size: 1_000_000) == {:error, :killed}
  end

  test "it works binary flooding" do
    code = ~S|for a <- 0..999_999_999_999, do: "#{a}"|

    assert eval(code, [], timeout: :infinity, max_heap_size: 1_000_000) == {:error, :killed}
  end
end
