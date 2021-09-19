defmodule Formular.Compiler.WithTest do
  use ExUnit.Case, async: true
  import Formular.Compiler, only: [extract_vars: 1]

  describe "`with`" do
    test "it works" do
      ast =
        quote do
          with {:ok, a} <- test(b) do
            :ok
          end
        end

      assert extract_vars(ast) == [:b]
    end
  end
end
