defmodule Formular.Compiler.CondTest do
  use ExUnit.Case, async: true
  import Formular.Compiler, only: [extract_vars: 1]

  describe "`with`" do
    test "it works" do
      ast =
        quote do
          cond do
            a == 1 ->
              :ok
          end
        end

      assert extract_vars(ast) == [:a]
    end

    test "it works with nested scope" do
      ast =
        quote do
          case target do
            %{a: a} ->
              cond do
                a == 1 ->
                  :ok
              end
          end
        end

      assert extract_vars(ast) == [:target]
    end
  end
end
