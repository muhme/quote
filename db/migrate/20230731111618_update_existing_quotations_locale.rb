class UpdateExistingQuotationsLocale < ActiveRecord::Migration[7.0]
  def up
    Quotation.find_each do |quotation|
      if quotation.categories.pluck(:id).include?(264) # English
        quotation.update(locale: 'en')
      else
        quotation.update(locale: 'de')
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
