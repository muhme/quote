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
    # from string
    assert_equal [categories(:one).id], Category.check("category():one) has the name public_category")
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
    assert_equal three_categories,
                 Category.check(Quotation.new(quotation: "Above the mountain is a cloud and the sun.")).sort
    I18n.locale = :de
    assert_equal three_categories,
                 Category.check(Quotation.new(quotation: "Über dem Berg ist eine Wolke und die Sonne.")).sort
    I18n.locale = :es
    assert_equal three_categories,
                 Category.check(Quotation.new(quotation: "Sobre la montaña hay una nube y el sol.")).sort
    I18n.locale = :ja
    assert_equal three_categories, Category.check(Quotation.new(quotation: "山の上には雲と太陽がある。")).sort
    I18n.locale = :uk
    assert_equal three_categories, Category.check(Quotation.new(quotation: "Над горою хмари і сонце.")).sort
  end

  # 20 Übermut
  # 21 Ärgernis
  # 22 Ödipus
  # 23 Straße
  test "check German Umlaut and Sharp S" do
    I18n.locale = :de
    assert_equal [20, 21, 22, 23],
                 Category.check("voller übermut läuft ödipus über die STRASSE - zum Ärgernis aller.").sort
  end

  # 24 Ei prevents ein or eine
  # 25 Sein prevents seine or seinem
  test "check German excluded words" do
    I18n.locale = :de
    assert_equal [20], Category.check("ein oder eine oder seine oder seinem Übermut")
    # cross check Ei and Sein are existing and found
    assert_equal [22, 24, 25], Category.check("Ödipus sein Ei bestimmt sein Sein").sort
  end

  # 30 car prevents cards
  # 31 star prevents start (but also disables stars)
  # 32 plan prevents plant
  test "check English excluded words" do
    I18n.locale = :en
    assert_equal [11], Category.check("We start to plant cards on the Mountain.")
    # cross check car, star and plan are existing and found
    assert_equal [11, 30, 31, 32], Category.check("The car plan to be a star in next mountain.").sort
  end

  # 40 時間厳守 (punctuality)
  # 41 時間     (time)
  test "check Japanese longest categories first" do
    I18n.locale = :ja
    assert_equal [41], Category.check("時間は人を待たない。") # Time waits for no one. (real)
    # cross check longer 時間厳守 is found
    assert_equal [40], Category.check("成功の秘訣は時間厳守です。") # The secret of success is punctuality. (real)
    # both?
    assert_equal [40, 41], Category.check("時間は貴重です、だから時間厳守を重視しましょう。").sort
    # Time is valuable, so we should value punctuality. (generic)
  end

  # 50 Humano (human)
  test "check spanish category name without last letter" do
    I18n.locale = :es
    assert_equal [50],
                 Category.check(
                   "Hay dos cosas infinitas: el universo y la estupidez humana, y no estoy seguro de la primera."
                 )
  end
end
