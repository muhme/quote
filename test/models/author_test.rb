require 'test_helper'

class AuthorTest < ActiveSupport::TestCase
  
  def setup
    @author = Author.new()
    @author.user_id = User.first.id
    @author.name = "Goethe"
    @author.firstname = "Johann Wolfgang von"
    @author.description = "deutscher Dichter (1749 - 1832)"
    @author.link = "https://de.wikipedia.org/wiki/Johann_Wolfgang_von_Goethe"
  end
  
  test "valid setup" do
    assert @author.valid?
  end
  
  test "author's name should not be empty" do
    @author.name = ""
    assert_not @author.valid?
  end
  
  test "author's first name, description and link could be empty" do
    @author.firstname = ""
    @author.description = ""
    @author.link = ""
    assert @author.valid?
  end

  test "author name, first name, description and link max length" do
    @author.name = "a" * 64
    @author.firstname = "a" * 64
    @author.description = "a" * 255
    @author.link = "a" * 255
    assert @author.valid?
  end
  
  test "author's name, first name, description and link don't have to be unique" do
    @author.save
    duplicate_author = @author.dup
    assert duplicate_author.valid?   # TODO but have to create warning in view
  end
  
  test "author's name should not be too long" do
    @author.name = "a" * 65
    assert_not @author.valid?
  end
  test "author's firstname should not be too long" do
    @author.firstname = "a" * 65
    assert_not @author.valid?
  end
  test "author's description should not be too long" do
    @author.description = "a" * 256
    assert_not @author.valid?
  end
  test "author's link should not be too long" do
    @author.link = "a" * 256
    assert_not @author.valid?
  end
  
  test "author public defaults to false" do
    @author.save
    assert @author.public == false
  end
  
  test "author needs user id" do
    @author.user_id = 0
    assert_not @author.valid?
  end
  
  test "get_author_name_or_blank method" do
    
    # first name and name set from setup
    assert_equal @author.get_author_name_or_blank, "Johann Wolfgang von Goethe"
    
    # w/o first name
    @author.firstname = ""
    assert_equal @author.get_author_name_or_blank, "Goethe"
  end
  
  test "get_linked_author_name_or_blank method" do
    
    # first name, name and link from setup
    assert_equal @author.get_linked_author_name_or_blank, "<a href=\"https://de.wikipedia.org/wiki/Johann_Wolfgang_von_Goethe\" target=\"quote_extern\">Johann Wolfgang von Goethe</a>"
    
    # w/o first name
    @author.firstname = ""
    assert_equal @author.get_linked_author_name_or_blank, "<a href=\"https://de.wikipedia.org/wiki/Johann_Wolfgang_von_Goethe\" target=\"quote_extern\">Goethe</a>"

    # w/o link
    @author.link = ""
    assert_equal @author.get_linked_author_name_or_blank, "Goethe"
    
  end
  
end
