Rails.application.routes.draw do
  
  get 'static_pages/joomla'
  get 'static_pages/humans'
  get 'static_pages/contact'
  get 'static_pages/joomla_english'
  get 'static_pages/project'
  get 'static_pages/use'
  get 'static_pages/help'
  get 'static_pages/list'
  get 'static_pages/search'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  
  root to: 'static_pages#list'
  
  # start from the beginning with a direct URL "joomla" instead "start/joomla"
  get 'joomla', to: 'static_pages#joomla'
  # map.connect 'joomla', :controller => 'start', :action => 'joomla'
  # map.connect 'joomla_english', :controller => 'start', :action => 'joomla'

  # dynamic generated humans.txt
  get 'humans.txt', to: 'static_pages#humans'
  # map.connect 'humans.txt', :controller => 'start', :action => 'humans'
  
  get 'categories/list_no_public', to: 'categories#list_no_public'
  get 'categories/list_by_letter/:letter', to: 'categories#list_by_letter'

  get 'authors/list_no_public', to: 'authors#list_no_public'
  get 'authors/list_by_letter/:letter', to: 'authors#list_by_letter'
  
  get 'quotations/list_no_public', to: 'quotations#list_no_public'
  get 'quotations/list_by_user/:user', to: 'quotations#list_by_user'
  get 'quotations/list_by_category/:category', to: 'quotations#list_by_category'
  get 'quotations/list_by_author/:author', to: 'quotations#list_by_author'
  
  # default controller routes
  resources :authors, :account, :categories, :quotations
  resources :static_pages, except: :show
  resources :users, except: [ :index, :show, :destroy ]
  resources :user_sessions # TODO reduce to some?
  
  get 'login', to: 'user_sessions#new'
# not needed in railscast    post 'login', to: 'user_sessions#create'
  get 'logout', to: 'user_sessions#destroy'
  
  get 'forbidden', to: 'static_pages#forbidden'
  get 'not_found', to: 'static_pages#not_found'

  # catch all
  match "*path", to: "static_pages#not_found", via: :all
  
end
