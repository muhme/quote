require "test_helper"

class QuotationsHelperTest < ActionView::TestCase
  def setup
    @empty = Quotation.new()
    @one = quotations(:one)
    @second = quotations(:second)
    @schiller_quote = quotations(:schiller_quote)
  end

  test "get_linked_author_and_source method" do
    # author, linked source
    assert_equal "Barbara, <a href=\"https://www.zitat-service.de\" target=\"quote_extern\">Zitat-Service</a>",
                 get_linked_author_and_source(@one)
    # author
    assert_equal "second author",
                 get_linked_author_and_source(@second)
    # nothing
    assert_equal "",
                 get_linked_author_and_source(@empty)
    # all
    # rubocop:disable Layout/LineLength
    assert_equal "<a href=\"https://en.wikipedia.org/wiki/Friedrich_Schiller\" target=\"quote_extern\">Friedrich Schiller</a>, <a href=\"https://www.projekt-gutenberg.org/schiller/wallens1/wall3305.html\" target=\"quote_extern\">Wallenstein, 1800</a>",
                 get_linked_author_and_source(@schiller_quote)
  end

  test "get_linked_quotation method" do
    assert_equal "<a class=\"no-break\" href=\"/quotations/1\">public_quotation to find public_category inside this quote</a>",
                 get_linked_quotation(@one)
  end
end
