class UpdateEmptyQuotationSourceAndSourceLinkToNull < ActiveRecord::Migration[7.0]

  # quotaions source and source_link are optional and saved as NULL in database if blank
  def up
    Quotation.where(source: '').update_all(source: nil)
    Quotation.where(source_link: '').update_all(source_link: nil)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
