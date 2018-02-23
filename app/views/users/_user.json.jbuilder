json.extract! user, :id, :login, :email, :admin, :crypted_password, :salt, :created_at, :updated_at
json.url user_url(user, format: :json)
