class Add1cId < ActiveRecord::Migration
  def up
    execute <<-SQL
    ALTER TABLE spree_products ADD xchange_id binary(16) not null, ADD UNIQUE(xchange_id)
SQL
  end
  def down
    execute <<-SQL
    ALTER TABLE spree_products DROP xchange_id
    SQL
  end

  #def change
  #  add_column :spree_products, :xchange_id, :binary, :null=>false, :limit=>16
  #end

end
