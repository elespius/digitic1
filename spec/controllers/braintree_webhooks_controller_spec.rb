require 'spec_helper'

describe BraintreeWebhooksController do
  before(:each) do
    @community = FactoryGirl.create(:community, :domain => "market.custom.org")
    braintree_payment_gateway = PaymentGateway.find_by_type("BraintreePaymentGateway")
    FactoryGirl.create(:community_payment_gateway, :community => @community, :payment_gateway => braintree_payment_gateway)

    # Refresh from DB
    @community.reload

    # Guard assert
    @community.braintree_in_use?.should be_true

    request.host = "market.custom.org"
  end

  describe "#hooks" do

    before(:each) do
      # Helpers for posting the hook
      @post_hook = ->(kind, id){
        signature, payload = BraintreeService.webhook_testing_sample_notification(
          @community,
          kind,
          id
        )

        # Do
        post :hooks, :bt_signature => signature, :bt_payload => payload
      }
    end

    it "rescues from error" do
      # Prepare
      @person = FactoryGirl.create(:person, :id => "123abc")

      # TODO Move these
      Braintree::Configuration.environment = :sandbox
      Braintree::Configuration.merchant_id = "vyhwdzxmbvw64z8v"
      Braintree::Configuration.public_key = "fp654nr3qzzz5k78"
      Braintree::Configuration.private_key = "119c7481abe69f6e4c1ca1d3d8ad17e3"

      signature, payload = BraintreeService.webhook_testing_sample_notification(
        @community,
        Braintree::WebhookNotification::Kind::SubMerchantAccountApproved,
        @person.id
      )

      post :hooks, :bt_signature => "#{signature}-invalid", :bt_payload => payload

      response.status.should == 400
    end

    describe "account creation hooks" do

      before(:each) do
        # Prepare
        @person = FactoryGirl.create(:person, :id => "123abc")
        @braintree_account = FactoryGirl.create(:braintree_account, :person => @person, :status => "pending")

        # Guard assert
        BraintreeAccount.find_by_person_id(@person.id).status.should == "pending"
      end

      it "listens for SubMerchantAccountApproved" do
        @post_hook.call(Braintree::WebhookNotification::Kind::SubMerchantAccountApproved, @person.id)
        BraintreeAccount.find_by_person_id(@person.id).status.should == "active"
      end

      it "listens for SubMerchantAccountDeclined" do
        @post_hook.call(Braintree::WebhookNotification::Kind::SubMerchantAccountDeclined, @person.id)
        BraintreeAccount.find_by_person_id(@person.id).status.should == "suspended"
      end
    end

    describe "transaction disbursed" do
      before(:each) do
        # Prepare
        @payment = FactoryGirl.create(:payment, :status => "paid", :braintree_transaction_id => "123abc", :type => "BraintreePayment")
        Payment.find_by_braintree_transaction_id("123abc").status.should == "paid"
      end

      it "listens for TransactionDisbursed" do
        @post_hook.call(Braintree::WebhookNotification::Kind::TransactionDisbursed, @payment.braintree_transaction_id)
        Payment.find_by_braintree_transaction_id(@payment.braintree_transaction_id).status.should == "disbursed"
      end
    end
  end
end