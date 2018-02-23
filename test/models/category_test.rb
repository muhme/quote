require 'test_helper'

class CategoryTest < ActiveSupport::TestCase
  
  def setup
    @user = User.new()
    @user.login = "category test"
    @user.save!
    @category = Category.new()
    @category.user_id = @user.id
    @category.category = "programming"
    @category.description = "All related to computer programming languages."
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
  
  test "category name and description max length" do
    @category.category = "a" * 64
    @category.description = "a" * 255
    assert @category.valid?
  end
  
  test "category names should be unique" do
    @category.category = "test"
    @category.save
    duplicate = @category.dup
    assert_not duplicate.valid?
  end
  
  test "category description should not be too long" do
    @category.description = "a" * 256
    assert_not @category.valid?
  end
  
  test "category description could be empty" do
    @category.description = ""
    assert @category.valid?
  end
  
  test "category description don't need to be unique" do
    @category.description = "not unique"
    @category.save
    duplicate = @category.dup
    @category.category = "test2"
    assert_not duplicate.valid?
  end
  
  test "category public defaults to false" do
    @category.save
    assert @category.public == false
  end
  
end