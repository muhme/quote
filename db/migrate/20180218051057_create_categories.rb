class CreateCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :categories do |t|
      t.string :category, :limit => 64, :null => false
      t.string :description, :limit => 255, :null => true

      t.timestamps
    end
  end
end
