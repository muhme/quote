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

  test "check" do
    I18n.locale = :de
    # from string
    assert_equal [categories(:one).id], Category.check("category():one) has the name public_category in :de")
    # from quote
    assert_equal [categories(:one).id], Category.check(quotations(:one))
    # nothing found
    assert_equal [], Category.check("Shoot for the moon. Even if you miss, you'll land among the stars.")
    assert_equal [], Category.check(quotations(:second))
    assert_equal [], Category.check("")
    assert_equal [], Category.check(nil)

    # multiple categories in all 5 locales
    three_categories = [categories(:mountain).id, categories(:cloud).id, categories(:sun).id].sort
    I18n.locale = :en
    assert_equal three_categories, Category.check(Quotation.new(quotation: "Above the mountain is a cloud and the sun.")).sort
    I18n.locale = :de
    assert_equal three_categories, Category.check(Quotation.new(quotation: "Über dem Berg ist eine Wolke und die Sonne.")).sort
    I18n.locale = :es
    assert_equal three_categories, Category.check(Quotation.new(quotation: "Sobre la montaña hay una nube y el sol.")).sort
    I18n.locale = :ja
    assert_equal three_categories, Category.check(Quotation.new(quotation: "山の上には雲と太陽がある。")).sort
    I18n.locale = :uk
    assert_equal three_categories, Category.check(Quotation.new(quotation: "Над Гора - хмара і сонце.")).sort

    # NICE German äöüß
    # NICE excluded words ei, sein
  end
  
end
