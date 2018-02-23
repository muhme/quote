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
  
  # default controller routes
  resources :authors, :account, :categories, :quotations, :users
  resources :static_pages, except: :show
  
  get 'account/login', to: 'account#login'
  
  get 'category/list_by_letter', to: 'category#list_by_letter'
  get 'author/list_by_letter', to: 'author#list_by_letter'
  get 'quotation/list_by_user/:user', to: 'quotation#list_by_user'
  
  # catch all
  match "*path", to: "static_pages#not_found", via: :all
  
end
