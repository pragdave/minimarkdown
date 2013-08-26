defmodule BlockParserTest do
  use ExUnit.Case
  import Minimarkdown.BlockParser

  test "convert to lines" do 
    input = [ "line\tone", "  line two\t", "\tline three" ]
    lines = convert_to_line_records(input)
    assert length(lines) == 3
    l = hd(lines)
    assert l.leading_spaces == 0
    assert l.text           == "line    one"
    l = hd(tl(lines))
    assert l.leading_spaces == 2
    assert l.text           == "  line two"
    l = hd(tl(tl(lines)))
    assert l.leading_spaces == 4
    assert l.text           == "    line three"
  end

  test "strip leading spaces when all lines at margin" do
    input = [ "line one", "line two", "line three" ]
    lines = convert_to_line_records(input) |> strip_leading_spaces

    assert length(lines) == 3
    l = hd(lines)
    assert l.leading_spaces == 0
    assert l.text           == "line one"
    l = hd(tl(lines))
    assert l.leading_spaces == 0
    assert l.text           == "line two"
    l = hd(tl(tl(lines)))
    assert l.leading_spaces == 0
    assert l.text           == "line three"
  end

  test "strip leading spaces when all lines are indented" do
    input = [ "    line one", "\tline two", "    line three" ]
    lines = convert_to_line_records(input) |> strip_leading_spaces

    assert length(lines) == 3
    l = hd(lines)
    assert l.leading_spaces == 0
    assert l.text           == "line one"
    l = hd(tl(lines))
    assert l.leading_spaces == 0
    assert l.text           == "line two"
    l = hd(tl(tl(lines)))
    assert l.leading_spaces == 0
    assert l.text           == "line three"
  end

  test "strip leading spaces when indentation varies" do
    input = [ "  line one", "\tline two", "  line three", "      line four" ]
    lines = convert_to_line_records(input) |> strip_leading_spaces

    assert length(lines) == 4
    l = hd(lines)
    assert l.leading_spaces == 0
    assert l.text           == "line one"
    l = hd(tl(lines))
    assert l.leading_spaces == 2
    assert l.text           == "  line two"
    l = hd(tl(tl(lines)))
    assert l.leading_spaces == 0
    assert l.text           == "line three"
    l = hd(tl(tl(tl(lines))))
    assert l.leading_spaces == 4
    assert l.text           == "    line four"
  end

  test "split empty input generates no blocks" do
    assert split_into_blocks([]) == []
  end

  test "split a single line generates a block containing that line" do
    input = [ "line1" ] |> convert_to_line_records
    assert split_into_blocks(input) == [ input ]
  end

  test "split two lines generates a block containing those lines" do
    input = [ "line1", "line2" ] |> convert_to_line_records
    assert split_into_blocks(input) == [ input ]
  end

  test "split two lines followed by a blank line generates a block containing two lines" do
    input = [ "line1", "line2" ] |> convert_to_line_records
    blank = [ "" ] |> convert_to_line_records
    result = split_into_blocks(input ++ blank)
    assert result == [ input ]
  end

  test "two lines separated by a blank line generates two blocks" do
    in1 = [ "line1" ] |> convert_to_line_records
    blank = [ "" ]    |> convert_to_line_records
    in2 = [ "line2" ] |> convert_to_line_records
    result = split_into_blocks(in1 ++ blank ++ in2)
    assert result == [ in1, in2 ]
  end

  test "two sets of lines separated by a blank line generates two blocks" do
    in1 = [ "line1a", "line1b" ] |> convert_to_line_records
    blank = [ "" ]               |> convert_to_line_records
    in2 = [ "line2a", "line2b" ] |> convert_to_line_records
    result = split_into_blocks(in1 ++ blank ++ in2)
    assert result == [ in1, in2 ]
  end
end
