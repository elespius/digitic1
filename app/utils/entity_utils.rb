module EntityUtils
  module_function

  # Define an entity constructor Proc, which returns a Hash
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
  #     .map { |model| Person.call(model) }
  #     .or_else(nil)
  # end
  #
  def define_entity(*ks)
    -> (opts = {}) {

      ks.reduce({}) do |memo, k|
        memo[k.to_sym] = opts[k]
        memo
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

  # rename keys in given hash (returns a copy) using the renames old_key => new_key mappings
  def rename_keys(renames, hash)
    renames.reduce(hash.dup) do |h, (old_key, new_key)|
      h[new_key] = h[old_key] if h.has_key?(old_key)
      h.delete(old_key)
      h
    end
  end


  VALIDATORS = {
    mandatory: -> (_, v, field) {
      if (v.to_s.empty?)
        "#{field}: Missing mandatory value."
      end
    },
    optional: -> (_, v, field) { nil },
    one_of: -> (allowed, v, field) {
      unless (allowed.include?(v))
        "#{field}: Value must be one of #{allowed}. Was: #{v}."
      end
    },
    string: -> (_, v, field) {
      unless (v.nil? || v.is_a?(String))
        "#{field}: Value must be a String. Was: #{v}."
      end
    },
    fixnum: -> (_, v, field) {
      unless (v.nil? || v.is_a?(Fixnum))
        "#{field}: Value must be a Fixnum. Was: #{v}."
      end
    },
    symbol: -> (_, v, field) {
      unless (v.nil? || v.is_a?(Symbol))
        "#{field}: Value must be a Symbol. Was: #{v}."
      end
    },
    callable: -> (_, v, field) {
      unless (v.nil? || v.respond_to?(:call))
        "#{field}: Value must respond to :call, i.e. be a Method or a Proc (lambda, block, etc.)."
      end
    },
    enumerable: -> (_, v, field) {
      unless (v.nil? || v.is_a?(Enumerable))
        "#{field}: Value must be an Enumerable. Was: #{v}."
      end
    },
    money: -> (_, v, field) {
      unless (v.nil? || v.is_a?(Money))
        "#{field}: Value must be a Money. Was: #{v}."
      end
    },
    validate_with: -> (validator, v, field) {
      unless (validator.call(v))
        "#{field}: Custom validation failed. Was: #{v}."
      end
    }
  }

  TRANSFORMERS = {
    const_value: -> (const, v) { const },
    default: -> (default, v) { v.nil? ? default : v },
    transform_with: -> (transformer, v) { transformer.call(v) }
  }

  def validator_or_transformer(k)
    if (VALIDATORS.keys.include?(k))
      :validators
    elsif (TRANSFORMERS.keys.include?(k))
      :transformers
    else
      raise(ArgumentError, "Illegal key #{k}. Not a known transformer or validator.")
    end
  end

  def parse_spec(spec)
    s = spec.dup
    opts = s.extract_options!
    parsed_spec = s.zip([nil].cycle)
      .to_h
      .merge(opts)
      .group_by { |(name, param)| validator_or_transformer(name) }

    parsed_spec[:validators] =
      (parsed_spec[:validators] || [])
      .map { |(name, param)| VALIDATORS[name].curry().call(param) }
    parsed_spec[:transformers] =
      (parsed_spec[:transformers] || [])
      .map { |(name, param)| TRANSFORMERS[name].curry().call(param) }

    parsed_spec
  end

  def parse_specs(specs)
    specs.reduce({}) do |fs, full_field_spec|
      f_name, *spec = *full_field_spec
      fs[f_name] = parse_spec(spec)
      fs
    end
  end

  def validate(validators, val, field)
    validators.reduce([]) do |res, validator|
      err = validator.call(val, field)
      res.push(err) unless err.nil?
      res
    end
  end

  def transform(transformers, val)
    transformers.reduce(val) do |v, transformer|
      transformer.call(v)
    end
  end

  def validate_and_transform(fields, opts)
    fields.reduce({errors: [], value: {}}) do |res, (name, spec)|
      res[:errors] = res[:errors].concat(validate(spec[:validators], opts[name], name))
      res[:value][name] = transform(spec[:transformers], opts[name])
      res
    end
  end

  # Define a builder function that constructs a new hash form an input hash.
  #
  # Builders require you to define a set of fields with (optional) sets of per field validators and transformers.
  #
  # Validators are applied to incoming field value and an exception (with a helpful error msg of course)
  # is thrown if the validation fails. Transformers allow you to manipulate the input value to produce the final output value for each field.
  #
  # Here's an example:
  #
  # Person = EntityUtils.define_builder(
  #   # const_value tranformer always returns the given const value, in this case :person
  #   [:type, const_value: :person],
  #
  #   # combining validators, must be string (:string) and not-nil (:mandatory)
  #   [:name, :string, :mandatory],
  #
  #   # :default transformer sets value if it's nil
  #   [:age, :optional, :fixnum, default: 8],
  #
  #   # accepts only :m, :f and :in_between
  #   [:sex, one_of: [:m, :f, :in_between]],
  #
  #   # custom validator, return true for valid values
  #   [:favorite_even_number, validate_with: -> (v) { v.nil? || v.even? }],
  #
  #   # custom transformer, return transformed value
  #   [:tag, :optional, transform_with: -> (v) { v.to_sym unless v.nil? }]
  # )
  #
  # See rspec tests for more examples and output
  def define_builder(*specs)
    fields = parse_specs(specs)

    -> (opts = {}) do
      raise(TypeError, "Expecting an input hash. You gave: #{opts}") unless opts.is_a? Hash

      result = validate_and_transform(fields, opts)

      unless (result[:errors].empty?)
        loc = caller_locations(2, 1).first
        raise(ArgumentError, "Error(s) in #{loc}: #{result[:errors]}")
      end

      result[:value]
    end
  end

end
