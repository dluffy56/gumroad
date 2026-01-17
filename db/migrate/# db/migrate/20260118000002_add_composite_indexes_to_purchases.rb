# db/migrate/20260118000002_add_composite_indexes_to_purchases.rb
class AddCompositeIndexesToPurchases < ActiveRecord::Migration[7.1]
  def change
    add_index :purchases, [:link_id, :purchaser_id], name: "index_link_id_purchaser_id"
    add_index :purchases, [:link_id, :email], name: "index_link_id_email"
  end
end
