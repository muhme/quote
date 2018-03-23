Rails.application.routes.draw do

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  
  root to: 'static_pages#list'

  # static_pages controller with historical and nicer 'start' URL
  get 'start/joomla'        , to: 'static_pages#joomla'
  get 'start/humans'        , to: 'static_pages#humans'
  get 'start/contact'       , to: 'static_pages#contact'
  get 'start/joomla_english', to: 'static_pages#joomla_english'
  get 'start/project'       , to: 'static_pages#project'
  get 'start/use'           , to: 'static_pages#use'
  get 'start/help'          , to: 'static_pages#help'
  get 'start/list'          , to: 'static_pages#list'
  # start from the beginning with a direct URL "joomla" instead "start/joomla"
  get 'joomla'              , to: 'static_pages#joomla'

  # dynamic generated humans.txt
  get 'humans.txt', to: 'static_pages#humans'
  
  get 'categories/list_no_public', to: 'categories#list_no_public'
  get 'categories/list_by_letter/:letter', to: 'categories#list_by_letter'

  get 'authors/list_no_public', to: 'authors#list_no_public'
  get 'authors/list_by_letter/:letter', to: 'authors#list_by_letter'
  
  get 'quotations/list_no_public', to: 'quotations#list_no_public'
  get 'quotations/list_by_user/:user', to: 'quotations#list_by_user'
  get 'quotations/list_by_category/:category', to: 'quotations#list_by_category'
  get 'quotations/list_by_author/:author', to: 'quotations#list_by_author'
  
  # default controller routes
  resources :authors, :categories, :quotations
  resources :users, except: [ :index, :show, :destroy ]
  resources :user_sessions, except: [ :index, :show, :edit, :update ]
  resources :password_resets, :only => [ :new, :create, :edit, :update ]
  
  get 'login', to: 'user_sessions#new'
  get 'logout', to: 'user_sessions#destroy'
  
  get 'forbidden', to: 'static_pages#forbidden'
  get 'not_found', to: 'static_pages#not_found'

  # catch all
  match "*path", to: "static_pages#not_found", via: :all
  
end
