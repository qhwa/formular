defmodule Formular.Compiler.ForTest do
  use ExUnit.Case, async: true
  import Formular.Compiler, only: [extract_vars: 1]

  describe "`for`" do
    test "it works" do
      ast =
        quote do
          for x <- 1..50, y <- 1..m, do: {x, y, z}
        end

      assert extract_vars(ast) == [:m, :z]
    end
  end
end
