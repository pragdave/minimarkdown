defmodule Minimarkdown.BlockParser do

  alias Minimarkdown.Line,      as: Line
  alias Minimarkdown.BlankLine, as: BlankLine

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
      |> Enum.min_by(fn leading_spaces -> 
                        if leading_spaces == 0 do # blank lines don't count
                          999_999
                        else
                          leading_spaces
                        end
                     end)

    if min_leading_spaces == 999_999, do: min_leading_spaces = 0 # all lines blank
    lines |> Enum.map(&Line.strip_leading_spaces(&1, min_leading_spaces))
  end

  @doc """
  Split lines into chunks separated by one or more blank lines.
  """

  def split_into_blocks(lines) do
    _split_into_blocks(lines, [[]])
  end

  defp _split_into_blocks([], blocks), do: recursive_reverse(blocks)

  # ignore trailing blank line
  defp _split_into_blocks([BlankLine[]], blocks), do: (IO.puts "trailing"; recursive_reverse(blocks))

  # add trailing non-blank to current block
  defp _split_into_blocks([line], [current_block|rest]) do
    _split_into_blocks([], [[line | current_block] | rest])
  end

  # ignore blank lines at start of block
  defp _split_into_blocks([BlankLine[] | tail], blocks) do
    _split_into_blocks(tail, blocks)
  end

  # a line followed by a blank line starts a new block
  defp _split_into_blocks([line, BlankLine[] | tail], [current_block|rest]) do
    _split_into_blocks(tail, [[], [line|current_block] | rest])
  end

  # otherwise a line gets added to the current block
  defp _split_into_blocks([line | tail], [current_block|rest]) do
    _split_into_blocks(tail, [[line|current_block]|rest])
  end


  # The first rule here removes the empty block which was created to hold a new list
  defp recursive_reverse([[]|list]), do: recursive_reverse(list)
  defp recursive_reverse(list) do
    list
    |> Enum.reverse
    |> Enum.map(&Enum.reverse/1)
  end

end