require "test_helper"

class CommentsHelperTest < ActionView::TestCase
  def setup
    @comment = Comment.new()
  end

  test "image_tag_for_commentable_type method" do
    @comment.commentable_type = "Category"
    # rubocop:disable Layout/LineLength
    assert_equal "<img alt=\"Image of an organizational structure, one superior square above three subordinate squares\" title=\"Category\" src=\"/images/category.png\" />",
                 image_tag_for_commentable_type(@comment)
    @comment.commentable_type = "Author"
    assert_equal "<img alt=\"Picture of woman with long hair and red top\" title=\"Author\" src=\"/images/author.png\" />",
                 image_tag_for_commentable_type(@comment)
    @comment.commentable_type = "Quotation"
    assert_equal "<img alt=\"Letter Z in green, as in logo\" title=\"Quote\" src=\"/images/quote.png\" />",
                 image_tag_for_commentable_type(@comment)
    # testing default to quotation
    @comment.commentable_type = "Cheesecake"
    assert_equal "<img alt=\"Letter Z in green, as in logo\" title=\"Quote\" src=\"/images/quote.png\" />",
                 image_tag_for_commentable_type(@comment)
  end
end
