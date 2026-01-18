# frozen_string_literal: true

class AddCompositeIndexesToPurchases < ActiveRecord::Migration[7.1]
  def change
    add_index :purchases, [:link_id, :email], name: "index_link_id_email", length: { email: 191 }
    end
end
