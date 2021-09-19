defmodule Formular.Compiler.ScopeTest do
  use ExUnit.Case, async: true

  import Formular.Compiler, only: [extract_vars: 1]

  describe "scopes" do
    test "it works" do
      ast =
        quote do
          case input do
            {:ok, x} ->
              x

            :error ->
              x
          end
        end

      assert extract_vars(ast) == [:input, :x]
    end
  end
end
