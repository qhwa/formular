defmodule Formular.Compiler.TopLevelTest do
  use ExUnit.Case, async: true

  import Formular.Compiler, only: [extract_vars: 1]

  describe "top level scope variables" do
    test "it works" do
      ast =
        quote do
          a
        end

      assert extract_vars(ast) == [:a]
    end

    test "it works with multiple variables" do
      ast =
        quote do
          a
          b
        end

      assert Enum.sort(extract_vars(ast)) == [:a, :b]
    end

    test "it works with assignments" do
      ast =
        quote do
          a = 5
          b
        end

      assert extract_vars(ast) == [:b]
    end

    test "it works with tuples" do
      ast =
        quote do
          {a, b} = {1, 2}
          {x, y, z} = {:a, :b, c}
        end

      assert extract_vars(ast) == [:c]
    end

    test "it works with maps" do
      ast =
        quote do
          %{a: a, b: b} = %{a: 1, b: 2}
          %{x: x, y: y, z: z} = %{x: :a, y: :b, z: c}
        end

      assert extract_vars(ast) == [:c]
    end

    test "it works with keyword lists" do
      ast =
        quote do
          [a: a, b: b] = [a: 1, b: 2]
          [x: x, y: y, z: z] = [x: :a, y: :b, z: c]
        end

      assert extract_vars(ast) == [:c]
    end

    test "it works pin operator" do
      ast =
        quote do
          ^x = 1
          %{y: ^y} = %{y: 3}
        end

      assert extract_vars(ast) |> Enum.sort() == [:x, :y]
    end
  end
end
