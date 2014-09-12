module MarketplaceService
  module EntityUtils
    module_function

    # Define an entity class, which is a Hash
    #
    # Usage:
    #
    # -- in some service / Entity --
    #
    # Person = MarketplaceService::EntityUtils.define_entity(
    #   :username,
    #   :password)
    #
    # -- in some service / Query --
    #
    # def person(person_id)
    #   Maybe(Person.where(person_id: person_id.first)
    #     .map { |model| Person.new(model) }
    #     .or_else(nil)
    # end
    #
    def define_entity(*ks)
      Class.new(Hash) { |klass|

        @__keys = ks

        def self.keys
          @__keys
        end

        def initialize(opts = {})
          self.class.keys.each { |k|
            self[k.to_sym] = opts[k] unless opts[k].nil?
          }
        end
      }
    end

    # Ensure first level keys are all symbols, not strings
    def hash_keys_to_symbols(hash)
      Hash[hash.map { |(k, v)| [k.to_sym, v] }]
    end

    # Turn active record model into a hash with string keys replaced with symbols
    def model_to_hash(model)
      return {} if model.nil?
      hash_keys_to_symbols(model.attributes)
    end

    # Usage:
    # Entities.from_hash(Entities.PaypalAccount, {email: "myname@email.com"})
    def from_hash(entity_class, data)
      entity = entity_class.new
      entity.members.each { |m| entity[m] = data[m] }
      entity
    end
  end
end
