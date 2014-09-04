# Modules in this file are included in both specs and cucumber steps.

module TestHelpers
  module CategoriesHelper

    DEFAULT_TRANSACTION_TYPES_FOR_TESTS = {
      Sell: {
        en: {
          name: "Selling", action_button_label: "Buy this item"
        }
      },
      Lend: {
        en: {
          name: "Lending", action_button_label: "Borrow this item"
        }
      },
      Rent: {
        en: {
          name: "Renting", action_button_label: "Rent this item"
        }
      },
      Request: {
        en: {
          name: "Requesting", action_button_label: "Offer"
        }
      },
      Service: {
        en: {
          name: "Selling services", action_button_label: ""
        }
      }
    }

    DEFAULT_CATEGORIES_FOR_TESTS = [
      {
        translations: [
          {locale: "en", name: "Items"},
          {locale: "fi", name: "Tavarat"}
        ],
        subcategories: [
          {
            translations: [
              {locale: "en", name: "Tools"},
              {locale: "fi", name: "Työkalut"}
            ]
          },
          { translations: [
            {locale: "en", name: "Books"},
            {locale: "fi", name: "Kirjat"}
            ]
          }
        ]
      },
      {
        translations: [
          {locale: "en", name: "Favors"},
          {locale: "fi", name: "Palvelukset"}
        ]
      },
      {
        translations: [
          {locale: "en", name: "Spaces"},
          {locale: "fi", name: "Tilat"}
        ]
      }
    ]

    def self.load_test_categories_and_transaction_types_to_db(community)
      TestHelpers::CategoriesHelper.load_categories_and_transaction_types_to_db(community, DEFAULT_TRANSACTION_TYPES_FOR_TESTS, DEFAULT_CATEGORIES_FOR_TESTS)
    end

    def self.load_categories_and_transaction_types_to_db(community, transaction_types, categories)
      # Load transaction types
      transaction_types.each do |type, translations|

        transaction_type = Object.const_get(type.to_s).create!(:type => type, :community_id => community.id)
        community.locales.each do |locale|
          translation = translations[locale.to_sym]

          if translation then
            tt_name = translation[:name]
            tt_action = translation[:action_button_label]
            transaction_type.translations.create!(:locale => locale, :name => tt_name, :action_button_label => tt_action)
          end
        end
      end

      # Load categories
      categories.each do |c|
        # Categories that do not have subcategories
        create_category_tree!(community, c)
      end
    end

    def self.create_category_tree!(community, category_hash, parent = nil)
      translations = category_hash[:translations] || []
      subcategories = category_hash[:subcategories] || []

      category = community.categories.create(parent_id: parent ? parent.id : nil)

      add_transaction_types(category, community.transaction_types)
      add_translations(category, translations)

      subcategories.each do |subcategory_hash|
        create_category_tree!(community, subcategory_hash, category)
      end
    end

    def self.add_transaction_types_and_translations_to_category(category, translations)

    end

    def self.add_transaction_types(category, transaction_types)
      transaction_types.each { |tt| category.transaction_types << tt }
      category.save
    end

    def self.add_translations(category, translations)
      translations.each do |translation|
        category.translations.create(translation)
      end
    end
  end

  # http://pullmonkey.com/2008/01/06/convert-a-ruby-hash-into-a-class-object/
  class HashClass
    def initialize(hash)
      hash.each do |k,v|
        self.instance_variable_set("@#{k}", v)  ## create and initialize an instance variable for this key/value pair
        self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})  ## create the getter that returns the instance variable
        self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})  ## create the setter that sets the instance variable
      end
    end
  end

  def generate_random_username(length = 12)
    chars = ("a".."z").to_a + ("0".."9").to_a
    random_username = "aa_kassitest"
    1.upto(length - 7) { |i| random_username << chars[rand(chars.size-1)] }
    return random_username
  end

  def set_subdomain(subdomain = "test")
    subdomain += "." unless subdomain.blank?
    @request.host = "#{subdomain}.lvh.me"
  end

  def sign_in_for_spec(person)
    # For some reason only sign_in (Devise) doesn't work so 2 next lines to fix that
    #sign_in person
    request.env['warden'].stub :authenticate! => person
    controller.stub :current_person => person
  end

  def find_or_build_category(category_name)
    TestHelpers::find_category_by_name(category_name) || FactoryGirl.build(:category)
  end

  module_function :find_or_build_category

  def find_category_by_name(category_name)
    Category.all.select do |category|
      category.display_name("en") == category_name
    end.first
  end

  module_function :find_category_by_name

  def find_transaction_type_by_name(transaction_type_name)
    TransactionType.all.select do |transaction_type|
      transaction_type.display_name("en") == transaction_type_name
    end.first
  end

  def find_numeric_custom_field_type_by_name(name)
    NumericField.all.select do |numeric_custom_field|
      numeric_custom_field.name("en") == name
    end.first
  end

  def index_finished?
    Dir[Rails.root.join(ThinkingSphinx::Test.config.indices_location, '*.{new,tmp}.*')].empty?
  end

  def wait_until_index_finished
    sleep 0.25 until index_finished?
  end

  def ensure_sphinx_is_running_and_indexed
    begin
      Listing.search("").total_pages
    rescue ThinkingSphinx::ConnectionError
      # Sphinx was not running so start it for this session
      ThinkingSphinx::Test.init
      ThinkingSphinx::Test.start_with_autostop
    end
    ThinkingSphinx::Test.index
    wait_until_index_finished()
  end

  # This is loaded only once before running the whole test set
  def load_default_test_data_to_db_before_suite
    community1 = FactoryGirl.create(:community, :domain => "test", :name => "Test", :consent => "test_consent0.1", :settings => {"locales" => ["en", "fi"]}, :real_name_required => true)
    community2 = FactoryGirl.create(:community, :domain => "test2", :name => "Test2", :consent => "KASSI_FI1.0", :settings => {"locales" => ["en"]}, :real_name_required => true, :allowed_emails => "@example.com")
    community3 = FactoryGirl.create(:community, :domain => "test3", :name => "Test3", :consent => "KASSI_FI1.0", :settings => {"locales" => ["en"]}, :real_name_required => true)

    [community1, community2, community3].each { |c| TestHelpers::CategoriesHelper.load_test_categories_and_transaction_types_to_db(c) }
  end

  # This is loaded before each test
  def load_default_test_data_to_db_before_test
    community1 = Community.find_by_domain("test")
    community2 = Community.find_by_domain("test2")
    community3 = Community.find_by_domain("test3")

    person1 = FactoryGirl.create(:person, :username => "kassi_testperson1", :is_admin => 0, "locale" => "en", :encrypted_password => "64ae669314a3fb4b514fa5607ef28d3e1c1937a486e3f04f758270913de4faf5", :password_salt => "vGpGrfvaOhp3", :given_name => "Kassi", :family_name => "Testperson1", :phone_number => "0000-123456", :created_at => "2012-05-04 18:17:04")
    person2 = FactoryGirl.create(:person, :username => "kassi_testperson2", :is_admin => false, :locale => "en", :encrypted_password => "72bf5831e031cbcf2e226847677fccd6d8ec6fe0673549a60abb5fd05f726462", :password_salt => "zXklAGLwt7Cu", :given_name => "Kassi", :family_name => "Testperson2", :created_at => "2012-05-04 18:17:04")

    FactoryGirl.create(:community_membership, :person => person1,
                        :community => community1,
                        :admin => 1,
                        :consent => "test_consent0.1",
                        :last_page_load_date => DateTime.now,
                        :status => "accepted" )

    FactoryGirl.create(:community_membership, :person => person2,
                      :community=> community1,
                      :admin => 0,
                      :consent => "test_consent0.1",
                      :last_page_load_date => DateTime.now,
                      :status => "accepted")

    FactoryGirl.create(:community_membership, :person => person2,
                      :community => community2,
                      :admin => 0,
                      :consent => "KASSI_FI1.0",
                      :last_page_load_date => DateTime.now,
                      :status => "accepted")

    FactoryGirl.create(:email,
    :person => person1,
    :address => "kassi_testperson1@example.com",
    :send_notifications => true,
    :confirmed_at => "2012-05-04 18:17:04")

    FactoryGirl.create(:email,
    :person => person2,
    :address => "kassi_testperson2@example.com",
    :send_notifications => true,
    :confirmed_at => "2012-05-04 18:17:04")
  end

end
