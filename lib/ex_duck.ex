defmodule ExDuck do
  @moduledoc """
  ExDuck is an Elixir Client for the DuckDuckGo Instant Answer API
  """

  @baseurl "https://duckduckgo.com"

  @doc """
  Query the DuckDuckGo Instant Answer API

  Will return the raw (JSON-decoded) results from the API

  Will raise in case of errors

  ## Examples

      iex> ExDuck.query!("Elixir Language") |> Map.get("Heading")
      "Elixir (programming language)"
  """
  def query!("") do
    %{
      type: "unknown",
      heading: "no results"
    }
  end

  def query!(topic) do
    Req.get!(@baseurl,
      params: %{
        q: topic,
        format: "json"
      }
    ).body
    |> Jason.decode!()
  end

  @doc """
  Query the DuckDuckGo Instant Answer API into a normalized answer

  Will return a map of normalized results from the API

  Will raise in case of errors

  This is exactly the same as calling

  ```elixir
  ExDuck.query!("elixir language") |> ExDuck.understand()
  ```

  ## Examples

      iex> ExDuck.answer!("Elixir Language").heading
      "Elixir (programming language)"
  """
  def answer!(topic) do
    query!(topic)
    |> understand()
  end

  @doc """
  Normalize a response from the DuckDuckGo Instant Answer API

  This is the real deal of this library. Querying the API is simply HTTP GET
  and JSON parsing. This function is where DuckDuckGo's several types of
  answers are parsed into consistent forms and non-responses are recognized
  (e.g. calculation answers). I'm not sold on my current state of
  normalization. But it does suffice.

  Calling `understand/1` with an already normalized answer is idempotent.

  ## Examples

      # a direct answer
      iex> elixir = ExDuck.query!("Elixir Language") |> ExDuck.understand()
      iex> elixir |> Map.keys()
      [:answer, :entity, :heading, :image, :image_caption, :information, :related, :source, :type, :url]

      # a category answer
      iex> simpsons_characters = ExDuck.query!("Simpsons Characters") |> ExDuck.understand()
      iex> simpsons_characters |> Map.keys()
      [:entries, :heading, :type]
      iex> simpsons_characters.type == "category"
      true

      # understanding is idempotent
      iex> elixir = ExDuck.query!("Elixir Language") |> ExDuck.understand()
      iex> elixir == ExDuck.understand(elixir)
  """
  def understand(answer = %{"Type" => "A"}) do
    image =
      Map.get(answer, "Image")
      |> case do
        nil -> ""
        "" -> ""
        path -> "#{@baseurl}#{path}"
      end

    %{
      type: "answer",
      heading: Map.get(answer, "Heading"),
      answer: Map.get(answer, "Abstract"),
      image: image,
      image_caption: caption(answer),
      entity: Map.get(answer, "Entity"),
      url: Map.get(answer, "AbstractURL"),
      source: Map.get(answer, "AbstractSource"),
      information:
        Map.get(answer, "Infobox")
        |> case do
          %{"content" => content} ->
            content
            |> Enum.filter(&(&1["data_type"] == "string" || &1["data_type"] == "twitter_profile"))
            |> Enum.map(
              &%{
                label: &1["label"],
                value: &1["value"]
              }
            )

          nil ->
            ""

          "" ->
            ""
        end,
      related: answer["RelatedTopics"] |> Enum.map(&related_topics/1) |> List.flatten()
    }
    |> Map.reject(fn {_key, value} -> Enum.member?(["", nil, []], value) end)
  end

  def understand(answer = %{"Type" => "C"}) do
    %{
      type: "category",
      heading: answer["Heading"],
      entries: answer["RelatedTopics"] |> Enum.map(&related_topics/1) |> List.flatten()
    }
  end

  def understand(answer = %{"Type" => "D"}) do
    %{
      type: "disambiguation",
      heading: "\"#{answer["Heading"]}\" has multiple possible answers",
      entries: answer["RelatedTopics"] |> Enum.map(&related_topics/1) |> List.flatten()
    }
  end

  def understand(answer = %{"RelatedTopics" => related}) when length(related) > 0 do
    understand(%{answer | "Type" => "C"})
  end

  def understand(%{"Type" => ""}) do
    %{
      type: "unknown",
      heading: "no results"
    }
  end

  def understand(%{"AnswerType" => "calc"}) do
    %{
      type: "calculation",
      heading: "Sorry. Calculations are not supported via the instant answer API"
    }
  end

  def understand(answer = %{"AnswerType" => "conversions"}) do
    %{
      type: "unit",
      heading: "\"#{answer["Heading"]}\" is a unit of measurement and has other meanings",
      entries: answer["RelatedTopics"] |> Enum.map(&related_topics/1) |> List.flatten()
    }
  end

  def understand(%{"AnswerType" => "dice_roll", "Answer" => answer}) when byte_size(answer) > 0 do
    %{
      type: "dice roll",
      answer: answer
    }
  end

  def understand(%{"AnswerType" => answer_type, "Answer" => answer}) when byte_size(answer) > 0 do
    %{
      type: answer_type,
      heading: "#{answer_type}",
      answer: answer
    }
  end

  def understand(%{"Type" => "E"}) do
    %{
      type: "error",
      heading: "error"
    }
  end

  def understand(answer), do: answer

  @doc """
  Translate a normalized answer or raw query results to markdown

  ## Examples

      iex> ExDuck.query!("Elixir Language")
      ...> |> ExDuck.to_markdown()
      ...> |> String.starts_with?("# Elixir (programming language)")
  """
  def to_markdown(answer = %{"Type" => _type}) do
    answer
    |> understand()
    |> to_markdown()
  end

  def to_markdown(answer = %{type: "answer"}) do
    main = """
    # #{answer[:heading]}

    #{if answer[:image] do
      "<img src=\"#{answer[:image]}\" alt=\"#{answer[:image_caption]}\" title=\"#{answer[:image_caption]}\" />"
    end}

    #{answer[:answer]}

    Source: #{answer[:source]} — #{answer[:url]}
    """

    info_table =
      if answer[:information] do
        start = """
        <table>
        <thead>
        <tr>
        <th>Label</th>
        <th>Value</th>
        </tr>
        </thead>
        <tbody>
        """

        body =
          Enum.map(answer[:information], fn entry ->
            """
            <tr>
            <td>#{entry[:label]}</td>
            <td>#{entry[:value]}</td>
            </tr>
            """
          end)
          |> Enum.join("\n")

        close = """
        </tbody>
        </table>
        """

        [start, body, close] |> Enum.join("\n")
      end

    related_topics =
      if answer[:related] do
        start = """
        <table>
        <thead>
        <tr>
        <th>Related</th>
        </tr>
        </thead>
        <tbody>
        """

        body =
          Enum.map(answer[:related], fn entry ->
            """
            <tr>
            <td>#{entry[:text]}</td>
            </tr>
            """
          end)
          |> Enum.join("\n")

        close = """
        </tbody>
        </table>
        """

        [start, body, close] |> Enum.join("\n")
      end

    [main, info_table, related_topics] |> Enum.join("\n")
  end

  def to_markdown(answer = %{type: "unknown"}) do
    """
    no results for #{answer[:type]}
    """
  end

  def to_markdown(answer = %{type: type}) when type in ["category", "disambiguation", "unit"] do
    category_count =
      answer[:entries]
      |> Enum.map(& &1[:category])
      |> Enum.uniq()
      |> Enum.count()

    to_markdown(answer, category_count)
  end

  def to_markdown(answer = %{type: "calculation"}) do
    answer[:heading]
  end

  def to_markdown(%{type: "dice roll", answer: rolls}) when byte_size(rolls) > 0 do
    answer =
      if Regex.match?(~r/[+-]/, rolls) do
        Abacus.eval(rolls) |> case do
          {:ok, result} -> "#{rolls} = #{result}"
          _ -> rolls
        end
      else
        rolls
      end

    """
    # Dice Roll : #{answer}
    """
  end

  def to_markdown(%{type: answer_type, answer: answer}) when byte_size(answer) > 0 do
    """
    # #{answer_type}

    #{answer}
    """
  end

  defp to_markdown(answer, 1) do
    header = """
    # #{answer[:heading]}

    <table>
    <thead>
    <tr>
    <th>Image</th>
    <th>Text</th>
    </tr>
    </thead>
    <tbody>
    """

    body =
      Enum.map(answer[:entries], fn entry ->
        """
        <tr>
        <td><img src="#{entry[:image]}" /></td>
        <td>#{entry[:text]}</td>
        </tr>
        """
      end)
      |> Enum.join("\n")

    footer = """
    </tbody>
    </table>
    """

    [header, body, footer] |> Enum.join("\n")
  end

  defp to_markdown(answer, _category_count) do
    header = """
    # #{answer[:heading]}

    <table>
    <thead>
    <tr>
    <th>Category</th>
    <th>Image</th>
    <th>Text</th>
    </tr>
    </thead>
    <tbody>
    """

    body =
      Enum.map(answer[:entries], fn entry ->
        """
        <tr>
        <td>#{entry[:category]}</td>
        <td><img src="#{entry[:image]}" /></td>
        <td>#{entry[:text]}</td>
        </tr>
        """
      end)
      |> Enum.join("\n")

    footer = """
    </tbody>
    </table>
    """

    [header, body, footer] |> Enum.join("\n")
  end

  defp related_topics(%{"Name" => category, "Topics" => topics}) do
    topics
    |> Enum.map(&related_topics(&1, category))
  end

  defp related_topics(entry) do
    related_topics(entry, "General")
  end

  defp related_topics(entry, category) do
    %{
      url: entry["FirstURL"],
      image: icon(entry),
      text: result(entry),
      category: category
    }
  end

  defp icon(%{"Icon" => %{"URL" => ""}}) do
    nil
  end

  defp icon(%{"Icon" => %{"URL" => path}}) do
    "#{@baseurl}#{path}"
  end

  defp icon(_entry) do
    nil
  end

  defp caption(%{"Heading" => heading, "Infobox" => %{"meta" => meta}}) do
    meta
    |> Enum.find(&(&1["label"] == "caption"))
    |> case do
      nil -> heading
      label -> label["value"] |> String.replace("\"", "&quot;")
    end
  end

  defp caption(_answer), do: nil

  defp result(%{"Result" => result}) do
    result
    |> String.replace(~r/<\/a>/, "</a><br />")
  end

  defp result(_entry) do
    nil
  end
end
