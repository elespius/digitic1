class BraintreePaymentGateway < PaymentGateway

  def can_receive_payments_for?(person, listing=nil)
    braintree_account = BraintreeAccount.find_by_person_id(person.id)
    braintree_account.present? && braintree_account.status == "active"
  end

  def new_payment_path(person, message, locale)
    edit_person_message_braintree_payment_path(:id => message.payment.id, :person_id => person.id.to_s, :message_id => message.id.to_s, :locale => locale)
  end

  def settings_path(person, locale)
    if person.braintree_account.blank?
      new_braintree_settings_payment_path(:person_id => person.id.to_s, :locale => locale)
    else
      edit_braintree_settings_payment_path(:person_id => person.id.to_s, :locale => locale)
    end
  end
  
  def has_additional_terms_of_use
    true
  end
  
  def name
    "braintree"
  end
end