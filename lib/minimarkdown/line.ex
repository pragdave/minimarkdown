  # type can be :regular, :code, or :blank
  defrecord Minimarkdown.Line, type: nil, leading_spaces: 0, text: "" do

    def dummy_leading_spaces, do: 999_999

    def from_string(string) do
      leading_spaces = case type = typeof(string) do
        :blank ->
          dummy_leading_spaces
        _ ->
          [{ _, leading_spaces }] = Regex.run(%r{^\s*}, string, return: :index)
          leading_spaces
      end
      new(type: type, leading_spaces: leading_spaces, text: string)
    end
    
    def blank_line do
      new(type: :blank, leading_spaces: dummy_leading_spaces)
    end

    defp typeof(""), do: :blank
    defp typeof(<< "```" :: utf8, _ :: binary >>), do: :code
    defp typeof(_),  do: :regular
    
    @doc """
    Given a line and a count, remove that number of leading characters
    from the line and reduce the leading space count. This is called
    when we normalize an entire document back to the margin.
    """
    def strip_leading_spaces(line = __MODULE__[type: :blank], _count), do: line
    def strip_leading_spaces(line, count) do
      if line.leading_spaces < count do
        line
      else
        __MODULE__.new(type:           line.type,
                       leading_spaces: line.leading_spaces - count,
                       text:           String.slice(line.text, count, 999999),
                       blank:          count == String.length(line.text))
      end
    end
    
    def expand_tabs(line) do
      line
      |> String.split("\t")
      |> Enum.map(&pad_to_4/1)
      |> Enum.join
      |> String.rstrip
    end
    
    defp pad_to_4(str) do
      case rem(String.length(str), 4) do
        0 -> str <> "    "
        1 -> str <> "   "
        2 -> str <> "  "
        3 -> str <> " "
      end
    end
  end
