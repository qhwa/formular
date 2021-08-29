A simple extendable DSL evaluator ![CI badget](https://github.com/qhwa/formular/actions/workflows/ci.yml/badge.svg)

**SECURITY NOTICE**

Please be aware that, Formular is not a safe sandbox at this version. The design purpose is more about compiling your configuration into runnable code inside the application. So if the code comes from some untrusted user inputs, it could potentially damage the system.

## Installation

```elixir
def deps do
  [
    {:formular, "~> 0.2"}
  ]
end
```

## Usage

### A configuration code example

```elixir
iex> discount_formula = ~s"
...>   case order do
...>     # old books get a big promotion
...>     %{book: %{year: year}} when year < 2000 ->
...>       0.5
...>   
...>     %{book: %{tags: tags}} ->
...>       # Elixir books!
...>       if ~s{elixir} in tags do
...>         0.9
...>       else
...>         1.0
...>       end
...>
...>     _ ->
...>       1.0
...>   end
...> "
...>
...> book_order = %{
...>   book: %{
...>     title: "Elixir in Action", year: 2019, tags: ["elixir"]
...>   }
...> }
...>
...> Formular.eval(discount_formula, [order: book_order])
{:ok, 0.9}
```

### Simple expressions

```elixir
# number
iex> Formular.eval("1", [])
{:ok, 1}

# plain string
iex> Formular.eval(~s["some text"], [])
{:ok, "some text"}
```

### Variables

Variables can be passed within the `binding` parameter.

```elixir
# bound value
iex> Formular.eval("1 + foo", [foo: 42])
{:ok, 43}
```

### Evaluating AST instead of plain string code

You may want to use AST instead of string for performance consideration. In this case, an AST can be passed to `eval/3`:

```elixir
iex> "a = b = 10; a * b" |> Code.string_to_quoted!() |> Formular.eval([])
{:ok, 100}
```

...so that you don't have to parse it every time before evaluating it.

### Functions

Kernel functions are limitedly supported. Only a picked list of Kernel functions are supported out of the box so that dangerouse functions such as `Kernel.exit/1` will not be invoked.

Refer to [the code](https://github.com/qhwa/formular/blob/master/lib/formular/default_functions.ex) for the whole list.

```elixir
# Kernel function
iex> Formular.eval("min(5, 100)", [])
{:ok, 5}

iex> Formular.eval("max(5, 100)", [])
{:ok, 100}
```

Custom functions can be provided in two ways, either in a binding lambda:

```elixir
# bound function
iex> Formular.eval("1 + add.(-1, 5)", [add: &(&1 + &2)])
{:ok, 5}
```
... or with a context module:

```elixir
defmodule MyContext do
  def foo() do
    42
  end
end

iex> Formular.eval("10 + foo", [], context: MyContext)
{:ok, 52}
```

**Directly calling to module functions in the expression are disallowed** for security reason. For example:

```elixir
iex> Formular.eval("Map.new", [])
{:error, :no_calling_module_function}

iex> Formular.eval("min(0, :os.system_time())", [])
{:error, :no_calling_module_function}
```

## License

MIT
