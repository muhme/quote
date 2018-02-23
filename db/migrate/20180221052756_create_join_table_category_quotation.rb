class CreateJoinTableCategoryQuotation < ActiveRecord::Migration[5.1]
  def change
    create_join_table :categories, :quotations do |t|
      # t.index [:category_id, :quotation_id]
      # t.index [:quotation_id, :category_id]
    end
  end
end
