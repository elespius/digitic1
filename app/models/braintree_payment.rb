# == Schema Information
#
# Table name: payments
#
#  id                       :integer          not null, primary key
#  payer_id                 :string(255)
#  recipient_id             :string(255)
#  organization_id          :string(255)
#  conversation_id          :integer
#  status                   :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  community_id             :integer
#  payment_gateway_id       :integer
#  sum_cents                :integer
#  currency                 :string(255)
#  type                     :string(255)      default("CheckoutPayment")
#  braintree_transaction_id :string(255)
#

class BraintreePayment < Payment
  attr_accessor :credit_card_number, :credit_card_expiration_date, :cardholder_name, :cvv
  attr_accessible :braintree_transaction_id

  monetize :sum_cents, :allow_nil => true

  def sum_exists?
    !sum_cents.nil?
  end

  def total_sum
    sum
  end

  # Build default payment sum by listing
  # Note: Consider removing this :(
  def default_sum(listing, vat=0)
    self.sum = listing.price
  end
end
