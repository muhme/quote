class AddLocaleToQuotation < ActiveRecord::Migration[7.0]
  def change
    add_column :quotations, :locale, :string
  end
end
