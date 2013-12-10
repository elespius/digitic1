require 'spec_helper'

describe BraintreeAccountsController do
  describe "#create" do
    before(:each) do
      @community = FactoryGirl.create(:community)
      braintree_payment_gateway = PaymentGateway.find_by_type("BraintreePaymentGateway")
      FactoryGirl.create(:community_payment_gateway, :community => @community, :payment_gateway => braintree_payment_gateway)
      
      @request.host = "#{@community.domain}.lvh.me"
      @person = FactoryGirl.create(:person)
      @community.members << @person
      sign_in_for_spec(@person)
    end

    it "should create braintree details with detailed information" do
      # Mock BraintreeService
      BraintreeService.should_receive(:create_merchant_account)
        .and_return(Braintree::SuccessfulResult.new(:merchant_account => HashClass.new(:status => "pending")))

      post :create, :braintree_account => {
        :person_id => @person.id,
        :first_name => "Joe",
        :last_name => "Bloggs",
        :email => "joe@14ladders.com",
        :phone => "5551112222",
        :address_street_address => "123 Credibility St.",
        :address_postal_code => "60606",
        :address_locality => "Chicago",
        :address_region => "IL",
        :date_of_birth => "1980-10-09",
        :ssn => "123-00-1234",
        :routing_number => "101000187",
        :account_number => "43759348798"
      }

      braintree_account = BraintreeAccount.find_by_person_id(@person.id)
      braintree_account.first_name.should be_eql("Joe")
      braintree_account.last_name.should be_eql("Bloggs")
      braintree_account.email.should be_eql("joe@14ladders.com")
      braintree_account.phone.should be_eql("5551112222")
      braintree_account.address_street_address.should be_eql("123 Credibility St.")
      braintree_account.address_postal_code.should be_eql("60606")
      braintree_account.address_locality.should be_eql("Chicago")
      braintree_account.address_region.should be_eql("IL")
      braintree_account.date_of_birth.should be_eql("1980-10-09")
      braintree_account.ssn.should be_eql("123-00-1234")
      braintree_account.routing_number.should be_eql("101000187")
      braintree_account.account_number.should be_eql("43759348798")
    end

    it "should not create braintree account with missing information" do
      # Mock BraintreeService
      BraintreeService.should_not_receive(:create_merchant_account)
      
      post :create, :braintree_account => {:person_id => @person.id, :first_name => "Joe", :last_name => "Bloggs"}
      BraintreeAccount.find_by_person_id(@person.id).should be_nil
    end

    it "should update braintree details" do
      id = BraintreeAccount.create(
        :person_id => @person.id,
        :first_name => "Joe",
        :last_name => "Bloggs",
        :email => "joe@14ladders.com",
        :phone => "5551112222",
        :address_street_address => "123 Credibility St.",
        :address_postal_code => "60606",
        :address_locality => "Chicago",
        :address_region => "IL",
        :date_of_birth => "1980-10-09",
        :ssn => "123-00-1234",
        :routing_number => "101000187",
        :account_number => "43759348798").id

      post :update, :id => id, :braintree_account => {
        :person_id => @person.id,
        :first_name => "Jane",
      }

      braintree_account = BraintreeAccount.find_by_person_id(@person.id)
      braintree_account.first_name.should be_eql("Jane")
      braintree_account.last_name.should be_eql("Bloggs")
      braintree_account.email.should be_eql("joe@14ladders.com")
      braintree_account.phone.should be_eql("5551112222")
      braintree_account.address_street_address.should be_eql("123 Credibility St.")
      braintree_account.address_postal_code.should be_eql("60606")
      braintree_account.address_locality.should be_eql("Chicago")
      braintree_account.address_region.should be_eql("IL")
      braintree_account.date_of_birth.should be_eql("1980-10-09")
      braintree_account.ssn.should be_eql("123-00-1234")
      braintree_account.routing_number.should be_eql("101000187")
      braintree_account.account_number.should be_eql("43759348798")
    end
  end
end