class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  # TODO
  def access?(a,b)
    return true
  end
end
