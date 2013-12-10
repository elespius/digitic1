class BraintreeWebhooksController < ApplicationController

  skip_before_filter :verify_authenticity_token
  skip_filter :check_email_confirmation, :dashboard_only

  before_filter do
    unless @current_community.braintree_in_use?
      BraintreeWebhooksController.log_error("Received webhook notification even though '#{@current_community.domain}' does not have Braintree in use")
      render :nothing => true, :status => 400 and return
    end
  end

  # This module contains all the handlers per notification kind.
  # Method name MUST match to the notification kind
  module Handlers
    class << self
      def sub_merchant_account_approved(notification, community)
        person_id = notification.merchant_account.id
        BraintreeWebhooksController.log_info("Approved submerchant account for person #{person_id}")

        braintree_account = BraintreeAccount.find_by_person_id(person_id)
        braintree_account.update_attributes(:status => "active")

        person = Person.find_by_id(person_id)

        PersonMailer.braintree_account_approved(person, community).deliver
      end

      def sub_merchant_account_declined(notification, community)
        person_id = notification.merchant_account.id
        BraintreeWebhooksController.log_info("Approved submerchant account for person #{person_id}")
        
        braintree_account = BraintreeAccount.find_by_person_id(person_id)
        braintree_account.update_attributes(:status => "suspended")
      end

      def transaction_disbursed(notification, community)
        transaction = notification.transaction
        BraintreeWebhooksController.log_info("Transaction #{transaction.id} disbursed")

        payment = Payment.find_by_braintree_transaction_id(transaction.id)
        payment.disbursed!
      end
    end
  end

  # Actions
  def challenge
    begin
      challenge_response = BraintreeService.webhook_notification_verify(@current_community, params[:bt_challenge])
    rescue Braintree::BraintreeError => bt_e
      BraintreeWebhooksController.log_error("Error while parsing challenge: #{bt_e.inspect}")
      render :nothing => true, :status => 400 and return
    end

    render :text => challenge_response, :status => 200
  end

  def hooks
    begin
      parsed_response = BraintreeService.webhook_notification_parse(@current_community, params[:bt_signature], params[:bt_payload])
    rescue Braintree::BraintreeError => bt_e
      BraintreeWebhooksController.log_error("Error while parsing webhook notification: #{bt_e.inspect}")
      render :nothing => true, :status => 400 and return
    end

    kind = parsed_response.kind.to_sym
    search_privates = true

    if Handlers.respond_to?(kind, search_privates)
      Handlers.send(kind, parsed_response, @current_community)
    else
      BraintreeWebhooksController.log_info("Received unimplemented webhook notification #{kind}: #{parsed_response.inspect}")
    end

    render :nothing => true
  end

  def self.log_info(msg)
    logger.info "[Braintree] #{msg}"
  end

  def self.log_error(msg)
    logger.error "[Braintree] #{msg}"
  end
end