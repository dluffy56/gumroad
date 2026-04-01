# frozen_string_literal: true

require "spec_helper"

describe "Checkout credit card input", :js, type: :system do
  def inject_stripe_card_mock_with_bad_input_font
    script = <<~JS
      (function() {
        const originalGetComputedStyle = window.getComputedStyle.bind(window);

        window.getComputedStyle = function(element, pseudoElement) {
          const style = originalGetComputedStyle(element, pseudoElement);
          if (!(element instanceof HTMLInputElement)) return style;

          return new Proxy(style, {
            get(target, prop) {
              if (prop === "fontFamily") return "MS Shell Dlg \\\\32";
              const value = Reflect.get(target, prop, target);
              return typeof value === "function" ? value.bind(target) : value;
            }
          });
        };

        function makeFakeStripe() {
          return {
            paymentRequest: function() {
              return {
                canMakePayment: function() { return Promise.resolve(null); },
                show: function() { return Promise.reject(new Error("Payment request not supported in test environment")); },
                abort: function() {},
                update: function() {},
                on: function() {},
                off: function() {}
              };
            },
            elements: function() {
              return {
                create: function(type, opts) {
                  if (type === "card") window.__cardElementCreateOptions = opts;
                  return {
                    mount: function() {},
                    unmount: function() {},
                    destroy: function() {},
                    on: function() {},
                    off: function() {},
                    update: function() {},
                    focus: function() {},
                    blur: function() {},
                    clear: function() {}
                  };
                },
                update: function() {},
                getElement: function() { return null; },
                fetchUpdates: function() { return Promise.resolve({}); }
              };
            },
            confirmCardPayment: function() {
              return Promise.resolve({ paymentIntent: { status: "succeeded" } });
            },
            confirmPayment: function() {
              return Promise.resolve({ paymentIntent: { status: "succeeded" } });
            },
            createToken: function() {
              return Promise.resolve({ token: { id: "tok_test_mock" } });
            },
            createPaymentMethod: function() {
              return Promise.resolve({ paymentMethod: { id: "pm_test_mock" } });
            },
            retrievePaymentIntent: function() {
              return Promise.resolve({ paymentIntent: null });
            },
            handleCardAction: function() {
              return Promise.resolve({ paymentIntent: { status: "succeeded" } });
            }
          };
        }

        window.Stripe = makeFakeStripe;
      })();
    JS

    @cdp_script_identifier = page.driver.browser.execute_cdp(
      "Page.addScriptToEvaluateOnNewDocument",
      source: script
    ).fetch("identifier")

    begin
      page.execute_script(script)
    rescue StandardError
    end
  rescue StandardError => e
    warn "Warning: Stripe card mock injection failed: #{e.message}"
  end

  def clear_card_input_mocks
    if @cdp_script_identifier
      page.driver.browser.execute_cdp("Page.removeScriptToEvaluateOnNewDocument", identifier: @cdp_script_identifier)
    end
  rescue StandardError => e
    warn "Warning: Stripe card mock cleanup failed: #{e.message}"
  ensure
    @cdp_script_identifier = nil
  end

  let(:product) { create(:product, price_cents: 1000) }

  after { clear_card_input_mocks }

  it "uses the configured app font for Stripe instead of the browser input font" do
    inject_stripe_card_mock_with_bad_input_font

    visit "/checkout?product=#{product.unique_permalink}&quantity=1"

    expect(page).to have_text("Card information")
    wait_until_true(sleep_interval: 0.1) { page.evaluate_script("!!window.__cardElementCreateOptions") }

    expected_font = page.evaluate_script("JSON.parse(document.getElementById('design-settings').dataset.settings).font.name")
    card_options = page.evaluate_script("window.__cardElementCreateOptions")

    expect(card_options.dig("style", "base", "fontFamily")).to eq(expected_font)
    expect(card_options.dig("style", "base", "fontFamily")).not_to eq("MS Shell Dlg \\\\32")
  end
end
