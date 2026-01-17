# frozen_string_literal: true

describe "Required product discounts", type: :request do
  let(:seller) { create(:user) }
  let(:old_product) { create(:product, user: seller) }
  let(:new_product) { create(:product, user: seller) }

  describe "multi-tier discounts" do
    let(:offer_code) do
      create(:offer_code,
        user: seller,
        code: "UPGRADE",
        amount_percentage: 100,
        fallback_amount_percentage: 50,
        required_product: old_product,
        required_product_max_age_months: 6
      )
    end

    before do
      offer_code.products << new_product
    end

    context "recent purchase (< 6 months)" do
      it "applies primary discount (100%)" do
        create(:purchase,
          link: old_product,
          email: "buyer@test.com",
          created_at: 3.months.ago
        )

        get compute_discount_offer_codes_path, params: {
          code: "UPGRADE",
          email: "buyer@test.com",
          products: { "0" => { permalink: new_product.unique_permalink, quantity: 1 } }
        }

        json = JSON.parse(response.body)
        expect(json["valid"]).to eq(true)

        discount = json["products_data"][new_product.unique_permalink]["discount"]
        expect(discount["type"]).to eq("percent")
        expect(discount["value"]).to eq(100)
      end
    end

    context "old purchase (> 6 months)" do
      it "applies fallback discount (50%)" do
        create(:purchase,
          link: old_product,
          email: "buyer@test.com",
          created_at: 8.months.ago
        )

        get compute_discount_offer_codes_path, params: {
          code: "UPGRADE",
          email: "buyer@test.com",
          products: { "0" => { permalink: new_product.unique_permalink, quantity: 1 } }
        }

        json = JSON.parse(response.body)
        expect(json["valid"]).to eq(true)

        discount = json["products_data"][new_product.unique_permalink]["discount"]
        expect(discount["type"]).to eq("percent")
        expect(discount["value"]).to eq(50)
      end
    end

    context "refunded purchase" do
      it "rejects discount" do
        create(:purchase,
          link: old_product,
          email: "buyer@test.com",
          created_at: 3.months.ago,
          refunded_at: 1.day.ago
        )

        get compute_discount_offer_codes_path, params: {
          code: "UPGRADE",
          email: "buyer@test.com",
          products: { "0" => { permalink: new_product.unique_permalink, quantity: 1 } }
        }

        json = JSON.parse(response.body)
        expect(json["valid"]).to eq(false)
        expect(json["error_code"]).to eq("missing_required_product")
      end
    end

    context "no purchase" do
      it "rejects discount" do
        get compute_discount_offer_codes_path, params: {
          code: "UPGRADE",
          email: "nobody@test.com",
          products: { "0" => { permalink: new_product.unique_permalink, quantity: 1 } }
        }

        json = JSON.parse(response.body)
        expect(json["valid"]).to eq(false)
        expect(json["error_message"]).to include("requires you to own")
      end
    end
  end
end
