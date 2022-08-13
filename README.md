# ExDuck

ExDuck is an Elixir library to query the [DuckDuckGo Instant Answer API](https://duckduckgo.com/api) and format the results.

## Installation

ExDuck can be installed by adding `ex_duck` to your list of dependencies in
`mix.exs`:

```elixir
def deps do
  [
    {:ex_duck, "~> 0.1.0"}
  ]
end
```

## API Documentation

Full API documentation is [published on hexdocs](https://hexdocs.pm/ex_duck).

## Usage

If you want the data for the answer then `ExDuck.answer!/1` is what you want. It queries the DuckDuckGo instant answer API and then parses the result into a map of relevant extracted data.

`ExDuck.query!/1` will return the raw results from the DuckDuckGo Instant Answer API.

`ExDuck.to_markdown/1` will convert a given answer or query result into markdown.

```elixir
iex> ExDuck.answer!("Elixir Language")
%{
  answer: "Elixir is a functional, concurrent, general-purpose programming language that runs on the BEAM virtual machine which is also used to implement the Erlang programming language. Elixir builds on top of Erlang and shares the same abstractions for building distributed, fault-tolerant applications. Elixir also provides productive tooling and an extensible design. The latter is supported by compile-time metaprogramming with macros and polymorphism via protocols. Elixir is used by companies such as PagerDuty, Discord, Brex, E-MetroTel, Pinterest, Moz, Bleacher Report, The Outline, Inverse, Divvy, FarmBot and for building embedded systems. The community organizes yearly events in the United States, Europe and Japan as well as minor local events and conferences.",
  entity: "programming language",
  heading: "Elixir (programming language)",
  image: "https://duckduckgo.com/i/6bb6708a.png",
  image_caption: "Elixir (programming language)",
  information: [
    %{
      label: "Paradigm",
      value: "multi-paradigm: functional, concurrent, distributed, process-oriented"
    },
    %{label: "First appeared", value: "2012"},
    %{label: "Typing discipline", value: "dynamic, strong, duck"},
    %{label: "Platform", value: "Erlang"},
    %{label: "License", value: "Apache License 2.0"},
    %{label: "Filename extensions", value: "ex.exs"}
  ],
  related: [
    %{
      category: "General",
      image: nil,
      text: "<a href=\"https://duckduckgo.com/Concurrent_computing\">Concurrent computing</a><br /> - Concurrent computing is a form of computing in which several computations are executed concurrently—during overlapping time periods—instead of sequentially—with one completing before the next starts.",
      url: "https://duckduckgo.com/Concurrent_computing"
    },
    %{
      category: "General",
      image: nil,
      text: "<a href=\"https://duckduckgo.com/Distributed_computing\">Distributed computing</a><br /> - Distributed computing is a field of computer science that studies distributed systems. A distributed system is a system whose components are located on different networked computers, which communicate and coordinate their actions by passing messages to one another from any system.",
      url: "https://duckduckgo.com/Distributed_computing"
    },
    %{
      category: "General",
      image: nil,
      text: "<a href=\"https://duckduckgo.com/c/Pattern_matching_programming_languages\">Pattern matching programming languages</a><br />",
      url: "https://duckduckgo.com/c/Pattern_matching_programming_languages"
    },
    %{
      category: "General",
      image: nil,
      text: "<a href=\"https://duckduckgo.com/c/Concurrent_programming_languages\">Concurrent programming languages</a><br />",
      url: "https://duckduckgo.com/c/Concurrent_programming_languages"
    },
    %{
      category: "General",
      image: nil,
      text: "<a href=\"https://duckduckgo.com/c/Functional_languages\">Functional languages</a><br />",
      url: "https://duckduckgo.com/c/Functional_languages"
    },
    %{
      category: "General",
      image: nil,
      text: "<a href=\"https://duckduckgo.com/c/Programming_languages\">Programming languages</a><br />",
      url: "https://duckduckgo.com/c/Programming_languages"
    },
    %{
      category: "General",
      image: nil,
      text: "<a href=\"https://duckduckgo.com/c/Software_using_the_Apache_license\">Software using the Apache license</a><br />",
      url: "https://duckduckgo.com/c/Software_using_the_Apache_license"
    }
  ],
  source: "Wikipedia",
  type: "answer",
  url: "https://en.wikipedia.org/wiki/Elixir_(programming_language)"
}
```
