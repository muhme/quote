class AddAuthorRefToQuotations < ActiveRecord::Migration[5.1]
  def change
    add_reference :quotations, :author, foreign_key: true
  end
end
