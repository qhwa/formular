defmodule Formular.Compiler.ClauseTest do
  use ExUnit.Case, async: true
  import Formular.Compiler, only: [extract_vars: 1]

  describe "`case`" do
    test "it works" do
      ast =
        quote do
          case b do
            :ok ->
              :ok

            %{x: ^x} ->
              :ok

            other ->
              {:other, other}
          end
        end

      assert extract_vars(ast) == [:b, :x]
    end
  end

  describe "function clause" do
    test "it works with anonymouse functions" do
      ast =
        quote do
          f = fn a, b ->
            c = a + b + x
          end
        end

      assert extract_vars(ast) == [:x]
    end

    test "it works named functions" do
      ast =
        quote do
          def my_f(a, b) do
            c = a + b + x
          end

          my_f(1, 2)
        end

      assert extract_vars(ast) == [:x]
    end
  end
end
