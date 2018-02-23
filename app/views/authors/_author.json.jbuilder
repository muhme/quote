json.extract! author, :id, :name, :firstname, :description, :link, :created_at, :updated_at
json.url author_url(author, format: :json)
