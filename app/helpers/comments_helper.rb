module CommentsHelper
  def image_tag_for_commentable_type(comment)
    if comment.commentable_type == "Category"
      return image_tag "category.png", alt: t("g.category_alt"), title: t("g.category")
    elsif comment.commentable_type == "Author"
      return image_tag "author.png", alt: t("g.author_alt"), title: t("g.author")
    end

    # else "Quotation"
    image_tag "zitat-service.svg", alt: t("g.quote_alt"), title: t("g.quote"), id: 'logo16'
  end
end
