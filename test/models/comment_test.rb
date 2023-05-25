require "test_helper"

class CommentTest < ActiveSupport::TestCase
  def setup
    I18n.locale = :en

    @comment = Comment.new()
    @comment.user_id = User.first.id
    @comment.comment = "What a nice day, isn't it?"
    @comment.commentable_type = "Category"
    @comment.commentable_id = 1
    @comment.locale = "de"
  end
  
  test "validate setup" do
    assert @comment.valid?
  end

  test "comment should not be empty" do
    @comment.comment = ""
    assert_not @comment.valid?
  end
  
  test "comment should not be too long" do
    @comment.comment = "a" * 513
    assert_not @comment.valid?
  end
  
  test "comment max length" do
    @comment.comment = "a" * 512
    assert @comment.valid?
  end

  test "should be valid with valid attributes" do
    comment = Comment.new(comment: "This is a valid comment", locale: "en", commentable: categories(:without_quotes))
    assert comment.valid?
  end

  test "should be invalid without a comment" do
    comment = Comment.new(locale: "en")
    assert_not comment.valid?
    assert_equal ["can't be blank"], comment.errors[:comment]
  end

  test "should be valid if comment has maximum length" do
    comment = Comment.new(comment: "a" * 512, locale: "de", commentable: categories(:one))
    assert comment.valid?
  end

  test "should be invalid if comment exceeds maximum length" do
    comment = Comment.new(comment: "a" * 513, locale: "es")
    assert_not comment.valid?
    assert_equal ["is too long (maximum is 512 characters)"], comment.errors[:comment]
  end

  test "should return the correct number of comments for an object" do
    category = categories(:without_comments)
    assert_equal 0, Comment.number_of(category)
    comment1 = Comment.create(user_id: 1, comment: "Erster Kommentar", locale: "de", commentable: category)
    assert_equal 1, Comment.number_of(category)
    comment2 = Comment.create(user_id: 1, comment: "第2回コメント", locale: "ja", commentable: category)
    comment3 = Comment.create(user_id: 1, comment: "Третій коментар", locale: "uk", commentable: category)
    assert_equal 3, Comment.number_of(category)
  end

  test "comment editable" do
    assert @comment.editable_by(users :first_user) # @comment creator is first_user
    assert @comment.editable_by(users :admin_user) 
    refute @comment.editable_by(users :second_user)
    refute @comment.editable_by(nil)
  end

end
