defmodule Minimarkdown.Tree do

  import Minimarkdown.BlockParser, only: [strip_leading_spaces: 1]

  alias Minimarkdown.Line,      as: Line

  defrecord Paragraph,    lines: []
  defrecord Code,         lines: []
  defrecord Heading,      level: 1, text: ""
  defrecord Blockquote,   lines: []
  defrecord UL,           lines: []
  defrecord OL,           lines: []

  @doc """
  Build a tree representing the document given a sequence of blocks
  """
  def build(blocks), do: _build(blocks, [])

  defp _build([], result) do
    result |> normalize_code
  end

  defp _build([block | tail], result) do
    _build(tail, [ process(block) | result ])
  end

  # here we're looking at individual blocks
  defp process(block = [Line[type: :code] | _rest]) do
    Code.new(lines: block)
  end

  # note single line block
  defp process([ line = Line[text: "=" <> _ ]]) do
    case atx_from(line.text) do
      nil ->
        Paragraph.new([line])
      params ->
        Heading.new(params)
    end
  end

  # note two line block
  defp process([ heading, underline = Line[text: "=" <> _]]) do
    case underline_heading(heading.text, underline.text) do
      nil ->
        Paragraph.new([heading, underline])
      params ->
        Heading.new(params)
    end
  end

  defp process([ heading, underline = Line[text: "-" <> _]]) do
    case underline_heading(heading.text, underline.text) do
      nil ->
        Paragraph.new([heading, underline])
      params ->
        Heading.new(params)
    end
  end

  defp process(block = [ Line[leading_spaces: leading_spaces, text: _, type: _]  | _rest ]) 
  when leading_spaces >= 4 do
    Code.new(lines: block)
  end

  defp process(block) do
    Paragraph.new(lines: block)
  end

  # helpers
  def atx_from(line) do
    line = Regex.replace(%r{[=\s]+$}, line, "")
    case  Regex.run(%r{^(=+)\s*(.+)}, line) do
      [ _, level, heading ] ->
        [ level: String.length(level), text: heading ]
      nil ->
        nil
    end
  end

  def ul_level(?=), do: 1
  def ul_level(?-), do: 2

  def underline_heading(heading, << type :: utf8, rest :: binary >> ) do
    if same_as(type, rest) do
      [ level: ul_level(type), text: heading ]
    else
      nil
    end
  end

  defp same_as(_char, ""), do: true
  defp same_as(char, << char :: utf8, rest :: binary >>), do: same_as(char, rest)


  defp normalize_code(tree_nodes) do
    tree_nodes
    |> merge_adjacent_code([])
    |> bring_code_to_margin
  end

  defp merge_adjacent_code( [], results), do: results

  defp merge_adjacent_code( [ c1 = Code[], c2 = Code[] | rest ], result) do
    merged = Code.new(lines: c2.lines ++ [ Line.blank_line ] ++  c1.lines)
    merge_adjacent_code(rest, [ merged | result ])
  end

  defp merge_adjacent_code( [ other | rest ], result ) do
    merge_adjacent_code(rest, [ other | result ])
  end

  defp bring_code_to_margin(tree_nodes) do
    tree_nodes |> Enum.map(&code_to_margin/1)
  end

  defp code_to_margin(code = Code[]) do
    code.update_lines(&strip_leading_spaces/1)
  end

  defp code_to_margin(other), do: other

end