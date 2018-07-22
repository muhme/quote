require 'test_helper'
include ERB::Util # for e.g. html_escape

class ApplicationHelperTest < ActionView::TestCase

  # this test is only very basic, for real test it is needed to set controller name and controller action, but even this is useless if controller name or controllers action name is changing, therefore page title is tested in system test
  test "page_title method" do
    assert_equal "Zitat-Service", page_title
  end
  
  test "nnsp method" do
    assert_equal "0 Zitate", nnsp(0, 'Zitat', 'Zitate')
    assert_equal "1 Zitat",  nnsp(1, 'Zitat', 'Zitate')
    assert_equal "2 Zitate", nnsp(2, 'Zitat', 'Zitate')
    assert_equal "4.711 Zitate", nnsp(4711, 'Zitat', 'Zitate')
  end
  
  test "nice_number method" do
    assert_equal "1.234", nice_number(1234)
    assert_equal "0", nice_number(0)
    assert_equal "42", nice_number(42)
    assert_equal "1.004", nice_number(1004)
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

  test "lh without link" do
    assert_nil lh("Donald J. Trump")
  end

  test "lh with http link" do
    assert_equal "<a popup=\"true\" href=\"http://www.zitat-service.de\">www.zitat-service.de</a>", lh("http://www.zitat-service.de")
  end

  test "lh with https link" do
    assert_equal "<a popup=\"true\" href=\"https://www.zitat-service.de\">www.zitat-service.de</a>", lh("https://www.zitat-service.de")
  end

end
