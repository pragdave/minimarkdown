defmodule LineTest do
  use ExUnit.Case
  import Minimarkdown.Line

  test "expand with no tabs" do
    assert expand_tabs("now is the time") == "now is the time"
  end

  test "expand with tabs and no spaces" do
    assert expand_tabs("\tn\to\tw") == "    n   o   w"
  end

  test "expand with tabs and some spaces" do
    assert expand_tabs("\tn  \to    \tw") == "    n   o       w"
  end

  test "creates a blank line with no text" do
    assert from_string("") == Minimarkdown.BlankLine[]
  end
end
