# frozen_string_literal: true

class AddRequiredProductToOfferCodes < ActiveRecord::Migration[7.1]
  def change
    add_reference :offer_codes,
                  :required_product,
                  foreign_key: { to_table: :links },
                  index: true

    add_column :offer_codes, :required_product_max_age_months, :integer
  end
end
