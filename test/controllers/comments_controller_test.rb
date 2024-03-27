require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
  end

  # POST /comments
  test "create comment" do
    post comments_url,
         params: { comment: { comment: "needs login first", commentable_type: "Category", commentable_id: 1,
                              locale: :en } }
    assert_forbidden
    login :first_user
    assert_difference('Comment.count', 1) do
      post comments_url,
           params: { comment: { comment: "works w/ login", commentable_type: "Category", commentable_id: 1,
                                locale: :en } }
    end
  end
  test "create comment failed" do
    login :first_user
    assert_no_difference 'Comment.count' do
      post comments_url,
           params: { comment: { comment: "", commentable_type: "Category", commentable_id: 1,
                                locale: :en } }
    end
    assert_response :unprocessable_entity # 422
  end

  # GET /comments/1/edit
  test "edit comment" do
    edit_comment_one_url = edit_comment_url id: (comments :one)
    get edit_comment_one_url
    assert_forbidden
    login :first_user
    get edit_comment_one_url
    assert_response :success # comment one was created by first_user
    get '/logout'
    login :second_user
    get edit_comment_one_url
    assert_forbidden
    login :admin_user
    get edit_comment_one_url
    assert_response :success
  end

  # PATCH /comments/1
  test "update comment" do
    login :first_user
    patch comment_url(comments :one), params: { comment: { comment: "Kuckuck" } } # default locale is "de"
    c = Comment.find((comments :one).id)
    assert_equal "Kuckuck", c.comment
    assert_equal "de", c.locale
    patch comment_url(comments :one), params: { comment: { comment: "cuckoo", locale: "en" } }
    c = Comment.find((comments :one).id)
    assert_equal "cuckoo", c.comment
    assert_equal "en", c.locale
    patch comment_url(comments :one), params: { comment: { comment: "cuco", locale: "es" } }
    c = Comment.find((comments :one).id)
    assert_equal "cuco", c.comment
    assert_equal "es", c.locale
    get '/logout'
    login :admin_user
    patch comment_url(comments :one), params: { comment: { comment: "зозуля", locale: "uk" } }
    c = Comment.find((comments :one).id)
    assert_equal "зозуля", c.comment
    assert_equal "uk", c.locale
    patch comment_url(comments :one), params: { comment: { comment: "ククー", locale: "ja" } }
    c = Comment.find((comments :one).id)
    assert_equal "ククー", c.comment
    assert_equal "ja", c.locale
    get '/logout'
    patch comment_url(comments :one), params: { comment: { comment: "crow", locale: "en" } }
    assert_forbidden
    c = Comment.find((comments :one).id)
    assert_equal "ククー", c.comment # unchanged
    assert_equal "ja", c.locale
    login :first_user
    patch comment_url(comments :one), params: { comment: { comment: "crow", locale: "en" } }
    c = Comment.find((comments :one).id)
    assert_equal "crow", c.comment
    assert_equal "en", c.locale
  end
  test "update comment failed" do
    login :first_user
    assert_no_difference 'Comment.count' do
      patch comment_url(comments :one), params: { comment: { comment: "", locale: "en" } }
    end
    assert_response :unprocessable_entity # 422
  end


  # DELETE /comments/1
  test "delete comment" do
    assert_no_difference 'Comment.count' do
      delete comment_url id: (comments :one)
    end
    assert_forbidden

    login :second_user
    assert_no_difference 'Comment.count' do
      delete comment_url id: (comments :one)
    end
    assert_forbidden
    get '/logout'

    login :first_user
    assert_difference('Comment.count', -1) do
      delete comment_url id: (comments :one)
    end
  end

  # GET /comments
  test "list comments" do
    get comments_url
    assert_response :forbidden
    get '/logout'
    login :first_user
    get comments_url
    assert_response :forbidden
    get '/logout'
    login :admin_user
    get comments_url
    assert_response :success
  end

  # GET /comments/list_by_user/1
  test "list by user method" do
    get "/comments/list_by_user/1"
    assert_response :success
    get "/comments/list_by_user/4711"
    assert_redirected_to root_url
  end
end
