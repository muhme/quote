require 'test_helper'

class CategoryTest < ActiveSupport::TestCase
  
  def setup
    @category = Category.new()
    @category.user_id = User.first.id
    @category.category = "programming"
  end
  
  test "validate setup" do
    assert @category.valid?
  end

  test "category name should not be empty" do
    @category.category = ""
    assert_not @category.valid?
  end
  
  test "category name should not be too long" do
    @category.category = "a" * 65
    assert_not @category.valid?
  end
  
  test "category name max length" do
    @category.category = "a" * 64
    assert @category.valid?
  end
  
  test "category names should be unique" do
    @category.category = "test"
    @category.save
    duplicate = @category.dup
    assert_not duplicate.valid?
  end

  test "category names should be unique case insensitive" do
    @category.category = "test"
    @category.save
    duplicate = @category.dup
    duplicate.category = "Test"
    assert_not duplicate.valid?
  end
  
  test "category public defaults to false" do
    @category.save
    assert @category.public == false
  end
  
end
