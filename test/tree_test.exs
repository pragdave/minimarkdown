defmodule TreeTest do
  use ExUnit.Case
  alias Minimarkdown.BlockParser, as: BP
  alias Minimarkdown.Tree,        as: Tree
  alias Minimarkdown.Tree.Code,   as: Code
  alias Minimarkdown.Tree.Paragraph, as: Paragraph
  alias Minimarkdown.Line,        as: Line

  test "empty document converts to empty tree" do
    assert Tree.build([]) == []
  end

  test "atx heading 1 recognized" do
    input = [ "= heading" ] |> BP.parse_document
    assert Tree.build(input) == [Tree.Heading[level: 1, text: "heading"]]
  end

  test "atx heading 2 recognized" do
    input = [ "== heading" ] |> BP.parse_document
    assert Tree.build(input) == [Tree.Heading[level: 2, text: "heading"]]
  end

  test "atx heading 3 recognized" do
    input = [ "=== heading" ] |> BP.parse_document
    assert Tree.build(input) == [Tree.Heading[level: 3, text: "heading"]]
  end

  test "underline h1 recognized" do
    input = [ "heading", "=======" ] |> BP.parse_document
    assert Tree.build(input) == [Tree.Heading[level: 1, text: "heading"]]
  end

  test "underline h2 recognized" do
    input = [ "heading", "-------" ] |> BP.parse_document
    assert Tree.build(input) == [Tree.Heading[level: 2, text: "heading"]]
  end


  # # # # # # Code 

  test "code block is recognized" do
    input = [ "``` elixir", "code 1", "", "code 2", "```" ] |> BP.parse_document
    assert Tree.build(input) == [ Tree.Code[lines: hd(input)] ]
  end

  test "indented code block is recognized" do
    input = """ |> String.split("\n") |> BP.parse_document
    line one

        def fred do
          123
        end
    """ 
    result = Tree.build(input)
    assert length(result) == 2
    [ p, c ] = result
    assert p == Paragraph[lines: [Line[type: :regular, leading_spaces: 0, text: "line one"]]]
    assert match?(Code[ lines: _ ], c)
    assert length(c.lines) == 3
    assert hd(c.lines).text == "def fred do"
  end

  test "indented code blocks separated by a blank line are merged" do
    input = """ |> String.split("\n") |> BP.parse_document
    line one

        def fred do
          123
        end

        def bert do
          543
        end
    """ 
    result = Tree.build(input)
    assert length(result) == 2
    [ p, c ] = result
    assert p == Paragraph[lines: [Line[type: :regular, leading_spaces: 0, text: "line one"]]]
    assert match?(Code[ lines: _ ], c)
    assert length(c.lines) == 7
    assert hd(c.lines).text == "def fred do"
  end
end

