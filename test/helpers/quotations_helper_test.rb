require "test_helper"

class QuotationsHelperTest < ActionView::TestCase

  def setup
    @author = Author.new()
    @author.name = "Gandi"
    @author.user_id = User.first.id
    @author.save!
    @quotation = Quotation.new()
    @quotation.user_id = User.first.id
    @quotation.quotation = "Be the change you wish to see." # Mahatma Gandhi
    @quotation.author_id = @author.id
    @quotation.save!
  end

  test "get_linked_author_and_source method with unknown author" do
    @quotation.author_id = 0 # unknown
    assert_equal "", get_linked_author_and_source(@quotation)
  end

  test "get_linked_author_and_source method" do

    # author w/o link and w/o quotations source as from initial setup
    assert_equal "Gandi", get_linked_author_and_source(@quotation)

    # w/ source
    @quotation.source = "source"
    assert_equal "Gandi, source", get_linked_author_and_source(@quotation)

    # w/ linked author
    @author.link = "https://de.wikipedia.org/wiki/Mohandas_Karamchand_Gandhi"
    @author.save!
    @quotation.source = ""
    @quotation.reload
    assert_equal '<a href="https://de.wikipedia.org/wiki/Mohandas_Karamchand_Gandhi" target="quote_extern">Gandi</a>', get_linked_author_and_source(@quotation)

    # w/ source and linked author
    @quotation.source = "source"
    assert_equal '<a href="https://de.wikipedia.org/wiki/Mohandas_Karamchand_Gandhi" target="quote_extern">Gandi</a>, source', get_linked_author_and_source(@quotation)

    # w/ linked source and linked author
    @quotation.source_link = "https://somewhere.org"
    assert_equal '<a href="https://de.wikipedia.org/wiki/Mohandas_Karamchand_Gandhi" target="quote_extern">Gandi</a>, <a href="https://somewhere.org" target="quote_extern">source</a>', get_linked_author_and_source(@quotation)
  end

  test "get_linked_quotation method" do
    # w/o locale, as locale is added by ApplicationControlle::default_url_options()
    assert_equal "<a href=\"/quotations/#{@quotation.id}\">Be the change you wish to see.</a>", get_linked_quotation(@quotation)
  end
end
