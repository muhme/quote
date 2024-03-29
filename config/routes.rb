Rails.application.routes.draw do
  # all joomla going now outside
  # was started from the beginning with a direct URL, e.g. "joomla" instead "start/joomla"
  get 'joomla'               => redirect(QUOTE_JOOMLA_WIKI[:de])
  get 'de/joomla'            => redirect(QUOTE_JOOMLA_WIKI[:de])
  get 'joomla_english'       => redirect(QUOTE_JOOMLA_WIKI[:en]) # used from Joomla module, version 1.4
  get 'start/joomla_english' => redirect(QUOTE_JOOMLA_WIKI[:en]) # old page link before I18n
  get 'en/joomla'            => redirect(QUOTE_JOOMLA_WIKI[:en])
  get 'es/joomla'            => redirect(QUOTE_JOOMLA_WIKI[:es])
  get 'ja/joomla'            => redirect(QUOTE_JOOMLA_WIKI[:ja])
  get 'uk/joomla'            => redirect(QUOTE_JOOMLA_WIKI[:uk])

  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    root to: "static_pages#list"

    # static_pages controller with historical and nicer 'start' URL
    get 'start/humans'  => 'static_pages#humans'
    get 'start/contact' => 'static_pages#contact'
    get 'start/project' => 'static_pages#project'
    get 'start/use'     => 'static_pages#use'
    get 'start/help'    => 'static_pages#help'
    get 'start/list'    => 'static_pages#list'

    # dynamic generated humans.txt
    get "humans.txt" => "static_pages#humans"

    get  'categories/list_no_public'              => 'categories#list_no_public'
    get  'categories/list_by_letter/:letter'      => 'categories#list_by_letter'
    get  'categories/list_duplicates'             => 'categories#list_duplicates'
    get  'authors/list_no_public'                 => 'authors#list_no_public'
    get  'authors/list_by_letter/:letter'         => 'authors#list_by_letter'
    get  'quotations/list_no_public'              => 'quotations#list_no_public'
    get  'quotations/list_by_user/:user'          => 'quotations#list_by_user'
    get  'quotations/list_by_category/:category'  => 'quotations#list_by_category'
    get  'quotations/list_by_author/:author'      => 'quotations#list_by_author'
    post 'quotations/search_author'               => 'quotations#search_author'
    get  'quotations/author_selected/:author_id'  => 'quotations#author_selected'
    get  'quotations/category_selected/:ids'      => 'quotations#category_selected'
    get  'quotations/delete_category/(:ids)'      => 'quotations#delete_category'
    get  'comments/list_by_user/:user'            => 'comments#list_by_user'

    # Hotwire Stimulus & Hotwire Turbo
    get  'users/show_avatar'                      => 'users#show_avatar'
    get  'users/recreate_avatar'                  => 'users#recreate_avatar'
    get  'users/take_gravatar'                    => 'users#take_gravatar'
    post 'users/upload_avatar'                    => 'users#upload_avatar'

    # default controller routes
    resources :authors, :categories, :quotations
    resources :users, except: [:show, :destroy]
    resources :user_sessions, except: [:index, :show, :edit, :update]
    resources :password_resets, only: [:new, :create, :edit, :update]
    resources :comments, only: [:index, :create, :edit, :update, :destroy]

    get "login"  => "user_sessions#new"
    get "logout" => "user_sessions#destroy"

    get "forbidden" => "static_pages#forbidden"
    get "not_found" => "static_pages#not_found"

    # see https://www.mintbit.com/blog/custom-404-500-error-pages-in-rails
    get "/400" => "static_pages#bad_request"
    get "/404" => "static_pages#not_found"
    get "/500" => "static_pages#internal_server"
    get "/422" => "static_pages#unprocessable"

    # catch all
    match "*path" => "static_pages#catch_all", via: :all
  end
end
