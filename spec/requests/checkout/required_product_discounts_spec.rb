# frozen_string_literal: true

require "spec_helper"


RSpec.describe "Required product discounts", type: :request do
  it "applies discount when customer owns the required product" do
    seller = create(:user)
    required_product = create(:product, user: seller)
    upgrade_product = create(:product, user: seller)

    email = "customer@example.com"

    create(
      :purchase,
      link: required_product,
      email: email,
      created_at: 1.month.ago
    )

    offer_code = create(
      :offer_code,
      user: seller,
      code: "UPGRADE50",
      amount_percentage: 50,
      required_product: required_product
    )

    offer_code.products << upgrade_product

    get compute_discount_offer_codes_path, params: {
      code: "UPGRADE50",
      email: email,
      products: {
        "0" => {
          permalink: upgrade_product.unique_permalink,
          quantity: 1
        }
      }
    }

    json = JSON.parse(response.body)

    expect(json["valid"]).to eq(true)
    expect(json["products_data"]).to be_present
  end
end
