defmodule Minimarkdown.BlockParser do

  alias Minimarkdown.Line, as: Line

  @moduledoc """
  Take a stream of lines and determine each one's type and indentation
  """

  def parse_document(raw_lines) do
    raw_lines 
    |> convert_to_line_records
    |> strip_leading_spaces
    |> split_into_blocks
  end

  def convert_to_line_records(raw_lines) do
    raw_lines 
    |> Enum.map(&(Line.expand_tabs(&1) |> Line.from_string))
  end

  def strip_leading_spaces(lines) do
    min_leading_spaces = 
      lines
      |> Enum.map(&(&1.leading_spaces))
      |> Enum.min

    if min_leading_spaces == Line.dummy_leading_spaces do
      lines  # All lines blank...
    else
      lines |> Enum.map(&Line.strip_leading_spaces(&1, min_leading_spaces))
    end
  end

  @doc """
  Split lines into chunks separated by one or more blank lines.
  """

  def split_into_blocks(lines) do
    _split_into_blocks(lines, [[]])
  end

  defp _split_into_blocks([], blocks), do: recursive_reverse(blocks)

  # add trailing non-blank to current block
  defp _split_into_blocks([line], [current_block|rest]) do
    _split_into_blocks([], [[line | current_block] | rest])
  end

  # ignore blank lines at start of block
  defp _split_into_blocks([Line[type: :blank] | tail], blocks) do
    _split_into_blocks(tail, blocks)
  end

  # A code block (a line starting ```) is terminated by another ``` line, and not a blank line)
  defp _split_into_blocks([ line = Line[type: :code] | tail ], [ [] | rest ]) do
    _split_into_code_block(tail, [ [line] | rest ])
  end

  # a line followed by a blank line starts a new block
  defp _split_into_blocks([line, Line[type: :blank] | tail], [current_block|rest]) do
    _split_into_blocks(tail, [[], [line|current_block] | rest])
  end

  # otherwise a line gets added to the current block
  defp _split_into_blocks([line | tail], [current_block|rest]) do
    _split_into_blocks(tail, [[line|current_block]|rest])
  end

  ## Handle code blocks. A line starting ``` ends it, otherwise we just collect
  defp _split_into_code_block([ line = Line[type: :code] | tail ], [ current_block | rest ]) do
    _split_into_blocks(tail, [ [], [ line | current_block ] | rest  ])
  end

  defp _split_into_code_block([ line | tail ], [ current_block | rest ]) do
    _split_into_code_block(tail, [ [ line | current_block ] | rest  ])
  end

  defp _split_into_code_block( [], code ) do
    raise %b{Unterminated code block: #{code |> Enum.reverse |> Enum.map(fn x -> x.text end) |> Enum.join("\n")}}
  end

  # The first rule here removes the empty block which was created to hold a new list
  defp recursive_reverse([[]|list]), do: recursive_reverse(list)
  defp recursive_reverse(list) do
    list |> Enum.reverse |> Enum.map(&Enum.reverse/1)
  end

end