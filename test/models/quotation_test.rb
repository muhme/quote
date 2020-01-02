require 'test_helper'

class QuotationTest < ActiveSupport::TestCase
  
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
  
  test "validate setup" do
    assert @quotation.valid?
  end
  
  test "quotation's quotation should not be empty" do
    @quotation.quotation = ""
    assert_not @quotation.valid?
  end
  
  test "quotation's quotation, source and source_link max length" do
    @quotation.quotation = "a" * 512
    @quotation.source = "a" * 255
    @quotation.source_link = "a" * 255
    assert @quotation.valid?
  end
  
  test "quotation's quotation should be unique" do
    @quotation.quotation = "test"
    @quotation.save
    duplicate = @quotation.dup
    assert_not duplicate.valid?
  end

  test "quotation's quotation should be unique case insensitive" do
    @quotation.quotation = "test"
    @quotation.save
    duplicate = @quotation.dup
    duplicate.quotation = "TEST"
    assert_not duplicate.valid?
  end

  test "quotation's quotation should not be too long" do
    @quotation.quotation = "a" * 513
    assert_not @quotation.valid?
  end
  test "quotation's source should not be too long" do
    @quotation.source = "a" * 256
    assert_not @quotation.valid?
  end
  test "quotation's source_link should not be too long" do
    @quotation.source_link = "a" * 256
    assert_not @quotation.valid?
  end
  
  test "quotation source and source_link could be empty" do
    @quotation.source = ""
    @quotation.source_link = ""
    assert @quotation.valid?
  end
  
  test "quotation' source and source_link don't need to be unique" do
    @quotation.save
    duplicate = @quotation.dup
    @quotation.quotation = "test2"
    assert_not duplicate.valid?
  end
  
  test "quotation public defaults to false" do
    @quotation.save
    assert @quotation.public == false
  end
  
  test "get_linked_author_and_source method" do
    # author w/o link and w/o quotations source as from initial setup
    assert_equal @quotation.get_linked_author_and_source, "Gandi"
    
    # w/ source
    @quotation.source = "source"
    assert_equal @quotation.get_linked_author_and_source, "Gandi, source"
    
    # w/ linked author
    @author.link = "https://de.wikipedia.org/wiki/Mohandas_Karamchand_Gandhi"
    @author.save!
    @quotation.source = ""
    @quotation.reload
    assert_equal @quotation.get_linked_author_and_source, '<a href="https://de.wikipedia.org/wiki/Mohandas_Karamchand_Gandhi" target="quote_extern">Gandi</a>'

    # w/ source and linked author
    @quotation.source = "source"
    assert_equal @quotation.get_linked_author_and_source, '<a href="https://de.wikipedia.org/wiki/Mohandas_Karamchand_Gandhi" target="quote_extern">Gandi</a>, source'
    
    # w/ linked source and linked author
    @quotation.source_link = "https://somewhere.org"
    assert_equal @quotation.get_linked_author_and_source, '<a href="https://de.wikipedia.org/wiki/Mohandas_Karamchand_Gandhi" target="quote_extern">Gandi</a>, <a href="https://somewhere.org" target="quote_extern">source</a>'
  end
  
  test "get_author_and_source_name method" do
    @quotation.source = "source"
    assert_equal @quotation.get_author_and_source_name, "Gandi, source"
  end

end
