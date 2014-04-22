class Add1cId < ActiveRecord::Migration
  def change
    add_column :spree_products, :xchange_id, 'binary(16)'
    add_column :spree_variants, :xchange_id, 'binary(16)'
    add_column :spree_taxons, :xchange_id, 'binary(16)'
  end
#  def up
#    #, ADD UNIQUE(xchange_id)
#    execute <<-SQL
#    ALTER TABLE spree_products ADD xchange_id binary(16);
#    ALTER TABLE spree_variants ADD xchange_id binary(16);
#    ALTER TABLE spree_taxons ADD xchange_id binary(16);
#SQL
#  end
#  def down
#    execute <<-SQL
#    ALTER TABLE spree_products DROP xchange_id;
#    ALTER TABLE spree_variants DROP xchange_id;
#    ALTER TABLE spree_taxons DROP xchange_id;
#    SQL
#  end
#
#  #def change
#  #  add_column :spree_products, :xchange_id, :binary, :null=>false, :limit=>16
#  #end

end
