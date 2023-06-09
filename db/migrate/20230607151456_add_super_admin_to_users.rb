class AddSuperAdminToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :super_admin, :boolean, default: false
    # heikoAdmin and heiko
    User.where(id: [1, 2]).update_all(super_admin: true)
  end
  def down
    # If needed, implement the rollback or revert logic here
    raise ActiveRecord::IrreversibleMigration
  end
end
