defmodule Formular.CompilerTest do
  use ExUnit.Case, async: true

  doctest Formular.Compiler

  describe "literal code support" do
    test "it supports atoms" do
      {:module, _} = Formular.compile_to_module!(":ok", :ok_module)
      assert Formular.eval({:module, :ok_module}, []) == {:ok, :ok}
    end

    test "it supports tuples" do
      {:module, _} = Formular.compile_to_module!("{:ok, :tuple}", :literal_tuple)
      assert Formular.eval({:module, :literal_tuple}, []) == {:ok, {:ok, :tuple}}
    end

    test "it supports numbers" do
      {:module, _} = Formular.compile_to_module!("3.14", :literal_number)
      assert Formular.eval({:module, :literal_number}, []) == {:ok, 3.14}
    end
  end
end
