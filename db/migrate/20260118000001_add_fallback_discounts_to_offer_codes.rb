# db/migrate/20260118000001_add_fallback_discounts_to_offer_codes.rb
class AddFallbackDiscountsToOfferCodes < ActiveRecord::Migration[7.1]
  def change
    add_column :offer_codes, :fallback_amount_percentage, :integer
    add_column :offer_codes, :fallback_amount_cents, :integer
  end
end
