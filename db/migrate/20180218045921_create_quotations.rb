class CreateQuotations < ActiveRecord::Migration[5.1]
  def change
    create_table :quotations do |t|
      t.string :quotation, :limit => 512, :null => false
      t.string :source, :limit => 255, :null => true
      t.string :source_link, :limit => 255, :null => true
      t.timestamps
    end
  end
end
