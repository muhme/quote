require 'test_helper'

class QuotationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @quotation_one = quotations(:one)
    @quotation_public_false = quotations(:public_false)
  end

  test "setup" do
    assert       @quotation_one.public
    assert_equal @quotation_one.user_id, users(:first_user).id
    assert_not   @quotation_public_false.public
    assert_equal @quotation_public_false.user_id, users(:first_user).id
  end

  test "should get index" do
    get quotations_url
    assert_response :success
    login :first_user
    get quotations_url
    assert_response :success
  end

  test "list_by_category method" do
    get '/quotations/list_by_category/1'
    assert_response :success
    get '/quotations/list_by_category/42000000'
    assert_redirected_to root_url
  end

  test "list_by_user method" do
    get '/quotations/list_by_user/1'
    assert_response :success
    get '/quotations/list_by_user/jhrefoqg'
    assert_redirected_to root_url
  end

  test "list_by_author" do
    get '/quotations/list_by_author/1'
    assert_response :success
    get '/quotations/list_by_author/x'
    assert_redirected_to root_url
  end

  test "404 for not existing quote" do
    id = rand 0..10000000000000
    get quotation_url id: id
    assert_response :not_found

    login :first_user
    get quotation_url id
    assert_response :not_found
  end

  test "should show public quote" do
    get quotation_url id: @quotation_one
    assert_response :success
    login :first_user
    get quotation_url @quotation_one
    assert_response :success
  end

  test "not public quote" do
    get quotation_url id: @quotation_public_false
    assert_response :success
    login :second_user
    get quotation_url @quotation_public_false
    assert_response :success
    get '/logout'
    login :first_user
    get quotation_url @quotation_public_false
    assert_response :success # quote is public false, but created by first user
    get quotation_url @quotation_one
    assert_response :success
    get '/logout'
    login :admin_user
    get quotation_url @quotation_public_false
    assert_response :success
  end

  test "should get new" do
    get new_quotation_url
    assert_forbidden
    login :first_user
    get new_quotation_url
    assert_response :success
  end

  test "should create quotation" do
    post quotations_url,
         params: { commit: "Speichern", quotation: { quotation: "Yes we can.", author_id: 0, locale: "en" } }
    assert_forbidden
    assert_difference('Quotation.count') do
      login :first_user
      post quotations_url,
           params: { commit: "Speichern", quotation: { quotation: "Yes we can.", author_id: 0, locale: "en" } }
    end
    assert_redirected_to quotation_url(Quotation.last)
    quotation = Quotation.find_by_quotation 'Yes we can.'
    assert_not quotation.public
  end

  test "should get edit" do
    get edit_quotation_url id: @quotation_one
    assert_forbidden
    login :first_user
    get edit_quotation_url @quotation_one
    assert_response :success
    get '/logout'
    login :second_user
    get edit_quotation_url @quotation_one
    assert_forbidden
    get '/logout'
    login :admin_user
    get edit_quotation_url @quotation_one
    assert_response :success
  end

  test "should update quotation" do
    login :first_user
    patch quotation_url(@quotation_one),
          params: { commit: "Save", quotation: { quotation: 'The early bird catches the worm', locale: "en" } }
    assert_redirected_to quotation_url @quotation_one
    get '/logout'
    login :admin_user
    patch quotation_url(@quotation_one),
          params: { commit: "Save", quotation: { quotation: 'The early bird catches the worm!', locale: "en" } }
    assert_redirected_to quotation_url @quotation_one
    get '/logout'
    patch quotation_url(@quotation_one),
          params: { commit: "Save", quotation: { quotation: 'The early bird catches the worm!!!', locale: "en" } }
    assert_forbidden
    login :first_user
    patch quotation_url(@quotation_one), params: { commit: "Save", quotation: { quotation: '' } }
    assert_response :unprocessable_entity # 422
    assert_match /1 fehler|1 error/i, @response.body
  end

  test "destroy quotation" do
    assert_no_difference 'Quotation.count' do
      delete quotation_url id: @quotation_one
    end
    assert_forbidden
    # try non-existing id
    assert_no_difference 'Quotation.count' do
      login :first_user
      delete quotation_url id: 47114711
      assert_response :not_found # 404
      get '/logout'
    end
    login :second_user
    assert_no_difference 'Quotation.count' do
      delete quotation_url @quotation_one
    end
    assert_forbidden
    get '/logout'
    login :first_user
    assert_difference('Quotation.count', -1) do
      delete quotation_url @quotation_one
    end
    assert_redirected_to quotations_url
    get '/logout'
    login :admin_user
    assert_difference('Quotation.count', -1) do
      delete quotation_url @quotation_public_false
    end
    assert_redirected_to quotations_url
  end

  test "list_no_public method" do
    get quotations_list_no_public_url
    assert_redirected_to forbidden_url
    login :first_user
    get quotations_list_no_public_url
    assert_redirected_to forbidden_url
    get '/logout'
    login :admin_user
    get quotations_list_no_public_url
    assert_response :success
  end

  test "pagination" do
    # not a number
    get '/quotations?page=X'
    assert_response :bad_request
    # have to be positive
    get '/quotations?page=-1'
    assert_response :bad_request
    # there is no page zero
    get '/quotations?page=0'
    assert_response :bad_request
    # 1st page
    get '/quotations?page=1'
    assert_response :success
    # 2nd page
    get '/quotations?page=2&locales='
    assert_response :success
    # out of range
    get '/quotations?page=42000000'
    assert_response :bad_request
    # together with (not existing) pattern, 1st page is always existing
    get '/quotations?page=1&pattern=eruhf2ghu'
    assert_response :success
    # (not existing) pattern out of range
    get '/quotations?page=2&pattern=wefgrifgi24i2'
    assert_response :bad_request
    # repeat tests for other paginate_by_sql with two tests each (one before and one after)
    get '/quotations/list_by_user/first_user?page=X'
    assert_response :bad_request
    get '/quotations/list_by_user/1?page=42000000'
    assert_response :bad_request
    get '/quotations/list_by_author/1?page=X'
    assert_response :bad_request
    get '/quotations/list_by_author/1?page=42000000'
    assert_response :bad_request
    get '/quotations/list_by_category/1?page=X'
    assert_response :bad_request
    get '/quotations/list_by_category/1?page=42000000'
    assert_response :bad_request
    login :admin_user
    get '/quotations/list_no_public?page=X'
    assert_response :bad_request
    get '/quotations/list_no_public?page=42000000'
    assert_response :bad_request
  end

  test "author_selected - forbidden without login" do
    # directly using the URL since named route helper isn't available
    get "/en/quotations/author_selected/#{authors(:one).id}"
    assert_forbidden
  end

  test "author selected - without locale, over all locales and with random author ids" do
    login :first_user
    locales = I18n.available_locales + [nil] # adding nil to test the scenario without a locale
    locales.each do |locale|
      random_author = Author.all.sample # select a random author from all authors
      path = ""
      path += "/#{locale}" if locale
      path += "/quotations/author_selected/#{random_author.id}"
      get path
      assert_response :success
      assert_equal "text/vnd.turbo-stream.html; charset=utf-8", @response.content_type
      assert_match /turbo-stream action="update"/, @response.body
      assert_match /<input type="search" name="author" id="author" value="/, @response.body
    end
  end

  test "category_selected - forbidden without login" do
    # directly using the URL since named route helper isn't available
    get "/de/quotations/category_selected/#{categories(:one).id}"
    assert_forbidden
  end

  # http://localhost:8102/de/quotations/category_selected/557,478,305-4,5
  #
  # <turbo-stream action="update" target="search_category_results"><template><turbo-frame id="search_category_results"></turbo-frame></template></turbo-stream><turbo-stream action="update" target="search_category_collected"><template><turbo-frame id="search_category_collected">
  #   <input type="hidden" name="quotation[category_ids][]" id="quotation_category_ids_" value="557,478,305" autocomplete="off" />
  #   <label class="font-size-smaller" for="category">3 Kategorien</label>
  #     <script>
  # //<![CDATA[
  # myCleanField("category")
  # //]]>
  # </script>
  #     <a class="animated" href="/de/quotations/delete_category/478,305-4,5">Bank<img alt="Rotes Kreuz" title="Löschen" border="0" src="/assets/cross-61afa45378baf5fbb81b0f0664d64291f9f51e22fad011a1ef99649cf5f3f3e3.png" /></a>
  #     <a class="none" href="/de/quotations/delete_category/557,305-4,5">Alkohol<img alt="Rotes Kreuz" title="Löschen" border="0" src="/assets/cross-61afa45378baf5fbb81b0f0664d64291f9f51e22fad011a1ef99649cf5f3f3e3.png" /></a>
  #     <a class="none" href="/de/quotations/delete_category/557,478-4,5">Ameise<img alt="Rotes Kreuz" title="Löschen" border="0" src="/assets/cross-61afa45378baf5fbb81b0f0664d64291f9f51e22fad011a1ef99649cf5f3f3e3.png" /></a>
  #         <span class="example"><br /> mit einem Klick hinzufügen: </span>
  #         <a href="/de/quotations/category_selected/4,557,478,305-4,5"><span class="example">China</span><img alt="Blitz" title="Hinzufügen" border="0" src="/assets/lightning-bf1d3f671d1761a63c677dbf9aeb9917d0d8bf3eae234937fe4b96c357e232cc.png" /></a>
  #         <a href="/de/quotations/category_selected/5,557,478,305-4,5"><span class="example">Liebe</span><img alt="Blitz" title="Hinzufügen" border="0" src="/assets/lightning-bf1d3f671d1761a63c677dbf9aeb9917d0d8bf3eae234937fe4b96c357e232cc.png" /></a>
  # </turbo-frame></template></turbo-stream>
  #
  test "category_selected - without locale, over all locales, selected and proposed ids" do
    login :first_user
    @categories = Category.all.sample(5)     # choose five categories
    @selected_categories = @categories[0..2] # three of them as selected
    @proposed_categories = @categories[3..4] # two of them as proposal
    selected_ids = @selected_categories.map(&:id).join(',')
    proposed_ids = @proposed_categories.map(&:id).join(',')
    locales = I18n.available_locales + [nil] # adding nil to test the scenario without a locale
    locales.each do |locale|
      path = ""
      path += "/#{locale}" if locale
      path += "/quotations/category_selected/#{selected_ids}-#{proposed_ids}"
      get path
      assert_response :success
      assert_equal "text/vnd.turbo-stream.html; charset=utf-8", @response.content_type
      # check for the presence of the input with correct value
      assert_select "input[name=?][value=?]", "quotation[category_ids][]", selected_ids
      # verify links for adding each proposed category (in the beginning)
      @proposed_categories.each do |category|
        link = ""
        link += locale ? "/#{locale}" : "/en" # locale defaults here to english if not set
        link += "/quotations/category_selected/#{category.id},#{selected_ids}-#{proposed_ids}"
        assert_select "a[href=?]", link
        assert_select "a.animated", count: 1
      end
    end
  end

  test "delete_category - forbidden without login" do
    # directly using the URL since named route helper isn't available
    get "/quotations/delete_category/#{categories(:one).id}"
    assert_forbidden
  end

  # http://localhost:8102/de/quotations/delete_category/557,478,305-4,5
  #
  #   <turbo-stream action="update" target="search_category_results"><template><turbo-frame id="search_category_results"></turbo-frame></template></turbo-stream><turbo-stream action="update" target="search_category_collected"><template><turbo-frame id="search_category_collected">
  #   <input type="hidden" name="quotation[category_ids][]" id="quotation_category_ids_" value="557,478,305" autocomplete="off" />
  #   <label class="font-size-smaller" for="category">3 Kategorien</label>
  #     <a class="none" href="/de/quotations/delete_category/478,305-4,5">Bank<img alt="Rotes Kreuz" title="Löschen" border="0" src="/assets/cross-61afa45378baf5fbb81b0f0664d64291f9f51e22fad011a1ef99649cf5f3f3e3.png" /></a>
  #     <a class="none" href="/de/quotations/delete_category/557,305-4,5">Alkohol<img alt="Rotes Kreuz" title="Löschen" border="0" src="/assets/cross-61afa45378baf5fbb81b0f0664d64291f9f51e22fad011a1ef99649cf5f3f3e3.png" /></a>
  #     <a class="none" href="/de/quotations/delete_category/557,478-4,5">Ameise<img alt="Rotes Kreuz" title="Löschen" border="0" src="/assets/cross-61afa45378baf5fbb81b0f0664d64291f9f51e22fad011a1ef99649cf5f3f3e3.png" /></a>
  #         <span class="example"><br /> mit einem Klick hinzufügen: </span>
  #         <a href="/de/quotations/category_selected/4,557,478,305-4,5"><span class="example">China</span><img alt="Blitz" title="Hinzufügen" border="0" src="/assets/lightning-bf1d3f671d1761a63c677dbf9aeb9917d0d8bf3eae234937fe4b96c357e232cc.png" /></a>
  #         <a href="/de/quotations/category_selected/5,557,478,305-4,5"><span class="example">Liebe</span><img alt="Blitz" title="Hinzufügen" border="0" src="/assets/lightning-bf1d3f671d1761a63c677dbf9aeb9917d0d8bf3eae234937fe4b96c357e232cc.png" /></a>
  # </turbo-frame></template></turbo-stream>
  #
  test "delete_category - without locale, over all locales, selected and proposed ids" do
    login :first_user
    @categories = Category.all.sample(5)     # choose five categories
    @selected_categories = @categories[0..2] # three of them as selected
    @proposed_categories = @categories[3..4] # two of them as proposal
    selected_ids = @selected_categories.map(&:id).join(',')
    proposed_ids = @proposed_categories.map(&:id).join(',')
    locales = I18n.available_locales + [nil] # adding nil to test the scenario without a locale
    locales.each do |locale|
      path = ""
      path += "/#{locale}" if locale
      path += "/quotations/delete_category/#{selected_ids}-#{proposed_ids}"
      get path
      assert_response :success
      assert_equal "text/vnd.turbo-stream.html; charset=utf-8", @response.content_type
      # check for the presence of the input with correct value
      assert_select "input[name=?][value=?]", "quotation[category_ids][]", selected_ids
      # verify links for adding each proposed category (in the beginning)
      @proposed_categories.each do |category|
        link = ""
        link += locale ? "/#{locale}" : "/en" # locale defaults here to english if not set
        link += "/quotations/category_selected/#{category.id},#{selected_ids}-#{proposed_ids}"
        assert_select "a[href=?]", link
        assert_select "a.animated", count: 0
      end
    end
  end
end
