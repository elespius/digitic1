# == Schema Information
#
# Table name: transaction_types
#
#  id                         :integer          not null, primary key
#  community_id               :integer
#  transaction_process_id     :integer
#  sort_priority              :integer
#  price_field                :boolean
#  price_quantity_placeholder :string(255)
#  price_per                  :string(255)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  url                        :string(255)
#  shipping_enabled           :boolean          default(FALSE)
#
# Indexes
#
#  index_transaction_types_on_community_id  (community_id)
#  index_transaction_types_on_url           (url)
#

class TransactionType < ActiveRecord::Base
  attr_accessible(
    :community_id,
    :price_field,
    :sort_priority,
    :price_quantity_placeholder,
    :price_per,
    :transaction_process_id,
    :shipping_enabled
  )

  belongs_to :community

  has_many :translations, :class_name => "TransactionTypeTranslation", :dependent => :destroy, inverse_of: :transaction_type
  has_many :category_transaction_types, :dependent => :destroy
  has_many :categories, :through => :category_transaction_types
  has_many :listings

  validates_presence_of :community

  validates :price_per, inclusion: { in: %w(day),
    message: "%{value} is not valid" }, allow_nil: true

  acts_as_url :url_source, scope: :community_id, sync_url: true, blacklist: %w{new all}

  def to_param
    url
  end

  def url_source
    Maybe(default_translation_without_cache).name.or_else(nil).tap { |translation|
      raise ArgumentError.new("Can not create URL for transaction type. Expected transaction type to have translation") if translation.nil?
    }
  end

  def default_translation_without_cache
    (translations.find { |translation| translation.locale == community.default_locale } || translations.first)
  end

  def display_name(locale)
    TranslationCache.new(self, :translations).translate(locale, :name)
  end

  def action_button_label(locale)
    TranslationCache.new(self, :translations).translate(locale, :action_button_label)
  end

  def self.find_by_url_or_id(url_or_id)
    self.find_by_url(url_or_id) || self.find_by_id(url_or_id)
  end
end
