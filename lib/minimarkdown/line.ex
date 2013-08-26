defrecord Minimarkdown.BlankLine, unused: 0


defrecord Minimarkdown.Line, leading_spaces: 0, text: "" do

  def from_string(string) do
    [{ _, leading_spaces }] = Regex.run(%r{^\s*}, string, return: :index)
    build(leading_spaces: leading_spaces, text: string)
  end

  def build([leading_spaces: 0, text: ""]), do: Minimarkdown.BlankLine.new
  def build(params),     do: new(params)

  @doc """
  Given a line and a count, remove that number of leading characters
  from the line and reduce the leading space count. This is called
  when we normalize an entire document back to the margin.
  """
  def strip_leading_spaces(line, count) do
    if line.leading_spaces < count do
      line
    else
      __MODULE__.new(leading_spaces: line.leading_spaces - count,
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


