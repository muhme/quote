class CreateAuthors < ActiveRecord::Migration[5.1]
  def change
    create_table :authors do |t|
      t.string :name, :limit => 64
      t.string :firstname,  :limit => 64
      t.string :description, :limit => 255
      t.string :link, :limit => 255

      t.timestamps
    end
  end
end
