defmodule KernelFunctionListTest do
  use ExUnit.Case, async: true

  import Formular.DefaultFunctions

  test "the full list" do
    functions = [
      !: 1,
      !=: 2,
      !==: 2,
      &&: 2,
      *: 2,
      +: 1,
      +: 2,
      ++: 2,
      ++: 2,
      -: 1,
      -: 2,
      --: 2,
      --: 2,
      ..: 2,
      "..//": 3,
      /: 2,
      <: 2,
      <=: 2,
      <>: 2,
      ==: 2,
      =~: 2,
      >: 2,
      >=: 2,
      abs: 1,
      and: 2,
      ceil: 1,
      div: 2,
      floor: 1,
      get_and_update_in: 2,
      get_and_update_in: 3,
      get_in: 2,
      hd: 1,
      if: 2,
      in: 2,
      inspect: 2,
      is_atom: 1,
      is_binary: 1,
      is_bitstring: 1,
      is_boolean: 1,
      is_exception: 1,
      is_exception: 2,
      is_float: 1,
      is_function: 1,
      is_integer: 1,
      is_list: 1,
      is_map: 1,
      is_map_key: 2,
      is_nil: 1,
      is_number: 1,
      is_pid: 1,
      is_port: 1,
      is_reference: 1,
      is_struct: 1,
      is_struct: 2,
      is_tuple: 1,
      length: 1,
      map_size: 1,
      max: 2,
      min: 2,
      not: 1,
      or: 2,
      pop_in: 1,
      pop_in: 2,
      put_elem: 3,
      put_in: 2,
      put_in: 3,
      rem: 2,
      round: 1,
      sigil_C: 2,
      sigil_D: 2,
      sigil_N: 2,
      sigil_R: 2,
      sigil_S: 2,
      sigil_T: 2,
      sigil_U: 2,
      sigil_W: 2,
      sigil_c: 2,
      sigil_r: 2,
      sigil_s: 2,
      sigil_w: 2,
      struct: 2,
      struct!: 2,
      tap: 2,
      then: 2,
      tl: 1,
      to_charlist: 1,
      to_string: 1,
      trunc: 1,
      tuple_size: 1,
      unless: 2,
      |>: 2,
      ||: 2
    ]

    for f = {name, arity} <- functions do
      if function_exported?(Kernel, name, arity) do
        assert f in kernel_functions(), "#{inspect(f)} is expected to be supported but not"
      end

      if macro_exported?(Kernel, name, arity) do
        assert f in kernel_macros(), "#{inspect(f)} is expected to be supported but not"
      end
    end
  end
end
