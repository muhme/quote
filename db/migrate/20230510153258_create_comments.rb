class CreateComments < ActiveRecord::Migration[7.0]
  def change
    create_table :comments do |t|
      t.string :comment, limit: 512
      t.string :locale, limit: 8

      t.references :commentable, polymorphic: true, index: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
