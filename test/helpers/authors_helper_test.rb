require "test_helper"
require Rails.root.join('app', 'helpers', 'application_helper')

class AuthorsHelperTest < ActionView::TestCase
  include ApplicationHelper

  def setup
    @schiller = authors(:schiller)
  end

  test "method name_comma_firstname" do
    # first and last name are empty or not existing
    assert_equal ", ", name_comma_firstname(nil, nil, :en)
    assert_equal ", ", name_comma_firstname("", nil, :en)
    assert_equal ", ", name_comma_firstname(nil, "", :en)
    assert_equal "、", name_comma_firstname(nil, nil, :ja)
    assert_equal "、", name_comma_firstname("", nil, :ja)
    assert_equal "、", name_comma_firstname(nil, "", :ja)

    # only last name exist
    assert_equal "name, ", name_comma_firstname("name", nil, :en)
    assert_equal "name, ", name_comma_firstname("name", "", :en)
    assert_equal "名、", name_comma_firstname("名", nil, :ja)
    assert_equal "名、", name_comma_firstname("名", "", :ja)

    # only first name exist
    assert_equal ", firstname", name_comma_firstname(nil, "firstname", :en)
    assert_equal ", firstname", name_comma_firstname("", "firstname", :en)
    assert_equal "、名前", name_comma_firstname(nil, "名前", :ja)
    assert_equal "、名前", name_comma_firstname("",  "名前", :ja)

    # first and last name exist
    assert_equal "Nachname, Vorname1 Vorname2", name_comma_firstname("Nachname", "Vorname1 Vorname2", :de)
    assert_equal "name, firstname", name_comma_firstname("name", "firstname", :en)
    assert_equal "名、名前", name_comma_firstname("名", "名前", :ja)
  end
end
