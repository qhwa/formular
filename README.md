A simple extendable DSL evaluator

## Installation

```elixir
def deps do
  [
    {:formular, github: "qhwa/formular"}
  ]
end
```

## Usage

### Simple expression


```elixir
# number
iex> Formular.eval("1", [])
{:ok, 1}

# plain string
iex> Formular.eval(~s["some text"], [])
{:ok, "some text"}

# binding value
iex> Formular.eval("1 + foo", [foo: 42])
{:ok, 43}

# binding function
iex> Formular.eval("1 + add.(-1, 5)", [add: &(&1 + &2)])
{:ok, 5}

# limited Kernel functions
iex> Formular.eval("min(5, 100)", [])
{:ok, 5}

iex> Formular.eval("max(5, 100)", [])
{:ok, 100}

iex> Formular.eval("count * 5", [count: 6])
{:ok, 30}

iex> Formular.eval("10 + foo", [])
warning: variable "foo" does not exist and is being expanded to "foo()", please use parentheses to remove the ambiguity or change the variable name
  nofile:1

** (CompileError) nofile:1: undefined function foo/0
    (stdlib 3.11) lists.erl:1354: :lists.mapfoldl/3
    (stdlib 3.11) lists.erl:1355: :lists.mapfoldl/3
```

## Selecing supported functions with context

A context module can be used to provide the functions in the formula.

```elixir
defmodule MyContext do
  def foo() do
    42
  end
end

iex> Formular.eval("10 + foo", [], context: MyContext)
{:ok, 52}
```

