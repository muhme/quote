require 'test_helper'
include ERB::Util # for e.g. html_escape

class ApplicationHelperTest < ActionView::TestCase

  test "nice_number method" do
    assert_equal "1.234", nice_number(1234)
    assert_equal "0", nice_number(0)
    assert_equal "42", nice_number(42)
  end

  test "author_name method simple" do
    assert_equal "James <b>B</b>rown", author_name("James", "Brown")
  end

  test "author_name method without firstname" do
    assert_equal "<b>B</b>rown", author_name("", "Brown")
    assert_equal "<b>B</b>rown", author_name(nil, "Brown")
  end

  test "author_name method with only firstname" do
    assert_equal "James", author_name("James", "")
    assert_equal "James", author_name("James", nil)
  end 

  test "author_name method with no name at all" do
    assert_equal "", author_name("", "")
    assert_equal "", author_name(nil, nil)
  end
  
  test "author_name method with long firstname" do
    assert_equal "XXXXXXXXXXXXXXXXXXXXXX... <b>B</b>rown", author_name("X" * 64, "Brown")
    assert_equal "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ...", author_name("Z" * 64, nil)
  end

  test "author_name method with long last name" do
    assert_equal "James <b>Y</b>YYYYYYYYYYYYYYYYYYYYYYY...", author_name("James", "Y" * 64)
    assert_equal "<b>W</b>WWWWWWWWWWWWWWWWWWWWWWWWWWWWW...", author_name(nil, "W" * 64)
  end  
  
  test "author_name method with long first and last name" do
    assert_equal "AAAAAAAAAAAAAAAAAAAAAA... <b>B</b>BBB...", author_name("A" * 64, "B" * 64)
  end
  
  test "author_name method with German Umlaut" do
    assert_equal "<b>Ä</b>sop", author_name(nil, "Äsop")
  end

end