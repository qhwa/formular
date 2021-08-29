Formular is a tiny extendable DSL evaluator. ![CI badget](https://github.com/qhwa/formular/actions/workflows/ci.yml/badge.svg)

It's a wrap around Elixir's `Code.eval_string/3` or `Code.eval_quoted/3`, with the following limitations:

  - No calling module functions;
  - No calling some functions which can cause VM to exit;
  - No sending messages;
  - (optional) memory usage limit;
  - (optional) execution time limit.

**SECURITY NOTICE**

Please be aware that, although it provides some security limitations, Formular does not aim to be a secure sandbox. The design purpose is more about compiling configurations into runnable code inside the application. So if the code comes from some untrusted user inputs, it could potentially damage the system.

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

[Online documentation](https://hexdocs.pm/formular/Formular.html)

## License

MIT
