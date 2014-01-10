class CustomFieldOptionTitle < ActiveRecord::Base
  attr_accessible :locale, :value
  validates :value, :locale, presence: true
end