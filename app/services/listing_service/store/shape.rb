module ListingService::Store::Shape

  TransactionTypeModel = ::TransactionType
  ListingUnitModel = ::ListingUnit

  NewShape = EntityUtils.define_builder(
    [:community_id, :fixnum, :mandatory],
    [:price_enabled, :bool, :mandatory],
    [:name_tr_key, :string, :mandatory],
    [:action_button_tr_key, :string, :mandatory],
    [:transaction_process_id, :fixnum, :mandatory],
    [:translations, :array, :optional], # TODO Only temporary
    [:shipping_enabled, :bool, :mandatory],
    [:units, :array, default: []], # Mandatory only if price_enabled
    [:price_quantity_placeholder, one_of: [nil, :mass, :time, :long_time]], # TODO TEMP
    [:url_source, :string, :mandatory]
  )

  Shape = EntityUtils.define_builder(
    [:id, :fixnum, :mandatory],
    [:transaction_type_id, :fixnum, :optional], # TODO Only temporary
    [:community_id, :fixnum, :mandatory],
    [:price_enabled, :to_bool, :mandatory], # to_bool, because there are NULL values in db
    [:name_tr_key, :string, :mandatory],
    [:action_button_tr_key, :string, :mandatory],
    [:transaction_process_id, :fixnum, :mandatory],
    [:translations, :array, :optional], # TODO Only temporary
    [:units, :array, :mandatory],
    [:shipping_enabled, :bool, :mandatory],
    [:price_quantity_placeholder, :to_symbol, one_of: [nil, :mass, :time, :long_time]] # TODO TEMP
  )

  UpdateShape = EntityUtils.define_builder(
    [:price_enabled, :bool], # to_bool, because there are NULL values in db
    [:name_tr_key, :string],
    [:action_button_tr_key, :string],
    [:translations, :array], # TODO Only temporary
    [:units, :array],
    [:shipping_enabled, :bool]
  )

  Unit = EntityUtils.define_builder(
    [:type, :to_symbol, one_of: [:piece, :hour, :day, :night, :week, :month, :custom]],
    [:translation_key, :optional] # TODO Validate or transform to TranslationKey
    )

  module_function

  # TODO Remove transaction_type_id
  def get(community_id:, transaction_type_id: nil, listing_shape_id: nil)
    shape_model = find_shape_model(
      community_id: community_id,
      transaction_type_id: transaction_type_id,
      listing_shape_id: listing_shape_id)

    transaction_type_id ||= shape_model.transaction_type_id

    tt_model = find_tt_model(
      community_id: community_id,
      transaction_type_id: transaction_type_id)

    from_model(tt_model, shape_model)
  end

  def get_all(community_id:)
    tt_models = find_tt_models(community_id: community_id)

    tt_models.map { |tt_model|
      shape_model = find_shape_model(
        community_id: community_id,
        transaction_type_id: tt_model.id)

      from_model(tt_model, shape_model)
    }
  end

  def create(community_id:, opts:)
    shape = NewShape.call(opts.merge(community_id: community_id))

    units = shape[:units].map { |unit| Unit.call(unit) }

    translations = opts[:translations] # Skip data type and validation, because this is temporary

    tt_model = nil
    shape_model = nil

    ActiveRecord::Base.transaction do
      url = uniq_url(shape[:url_source], shape[:community_id])
      shape_with_url = shape.except(:url_source).merge(url: url)
      shape_with_name = shape.except(:url_source).merge(name: url)

      # Save to TransactionType model
      create_tt_opts = to_tt_model_attributes(shape_with_url).except(:units, :translations)
      tt_model = TransactionType.create!(create_tt_opts)

      # Save to ListingShape model
      shape_model = ListingShape.create!(shape_with_name.merge(transaction_type_id: tt_model.id).except(:units, :translations))

      # Save units
      units.each { |unit|
        tt_model.listing_units.create!(to_unit_model_attributes(unit).merge(listing_shape_id: shape_model.id))
      }
      translations.each { |tr| tt_model.translations.create!(tr) }
    end

    from_model(tt_model, shape_model)
  end

  def update(community_id:, transaction_type_id: nil, listing_shape_id: nil, opts:)
    shape_model = find_shape_model(
      community_id: community_id,
      transaction_type_id: transaction_type_id,
      listing_shape_id: listing_shape_id)

    return nil if shape_model.nil?

    transaction_type_id ||= transaction_type_id

    tt_model = find_tt_model(
      community_id: community_id,
      transaction_type_id: transaction_type_id)

    return nil if tt_model.nil?

    update_shape = UpdateShape.call(opts.merge(community_id: community_id))

    units = update_shape[:units].map { |unit| Unit.call(unit) }

    translations = opts[:translations] # Skip data type and validation, because this is temporary

    # TODO We should be able to create transaction_type without community
    ActiveRecord::Base.transaction do
      update_tt_opts = HashUtils.compact(to_tt_model_attributes(update_shape)).except(:units, :translations)
      tt_model.update_attributes(update_tt_opts)

      unless units.nil?
        tt_model.listing_units.destroy_all
        units.each { |unit| tt_model.listing_units.build(to_unit_model_attributes(unit).merge(listing_shape_id: shape_model.id)) }
      end

      unless translations.nil?
        tt_model.translations.destroy_all
        translations.each { |tr| tt_model.translations.build(tr) }
      end

      tt_model.save!

      # Save to ListingShape model
      shape_model.update_attributes!(HashUtils.compact(update_shape).merge(transaction_type_id: tt_model.id).except(:units, :translations))
    end

    from_model(tt_model, shape_model)
  end

  # private

  def from_model(tt_model, shape_model)
    Maybe(tt_model).map { |m|
      hash = from_tt_model_attributes(EntityUtils.model_to_hash(m))

      hash[:units] = m.listing_units.map { |unit_model|
        Unit.call(from_unit_model_attributes(EntityUtils.model_to_hash(unit_model)))
      }

      hash[:id] = shape_model.id

      Shape.call(hash)
    }.or_else(nil)
  end

  def to_unit_model_attributes(hash)
    HashUtils.rename_keys(
      {
        type: :unit_type
      }, hash)
  end

  def from_unit_model_attributes(hash)
    HashUtils.rename_keys(
      {
        unit_type: :type
      }, hash)
  end

  def to_tt_model_attributes(hash)
    HashUtils.rename_keys(
      {
        price_enabled: :price_field
      }, hash).except(:units)
  end

  def from_tt_model_attributes(model_hash)
    hash = HashUtils.rename_keys(
      {
        price_field: :price_enabled,
        id: :transaction_type_id
      }, model_hash).except(:units)
  end

  def find_tt_model(community_id:, transaction_type_id:)
    TransactionTypeModel.where(community_id: community_id, id: transaction_type_id).first
  end

  def find_tt_models(community_id:)
    TransactionTypeModel.where(community_id: community_id)
  end

  def find_shape_model(community_id:, listing_shape_id: nil, transaction_type_id: nil)
    community_shapes = ListingShape.where(community_id: community_id)

    if listing_shape_id
      community_shapes.where(id: listing_shape_id).first
    elsif transaction_type_id
      community_shapes.where(transaction_type_id: transaction_type_id).first
    else
      raise ArgumentError.new("Can not find listing shape without id.")
    end

  end

  def uniq_url(url_source, community_id)
    blacklist = ['new', 'all']
    current_url = url_source.to_url
    base_url = current_url

    transaction_types = TransactionTypeModel.where(community_id: community_id)

    i = 1
    while blacklist.include?(current_url) || transaction_types.find { |tt| tt.url == current_url }.present? do
      current_url = "#{base_url}#{i}"
      i += 1
    end
    current_url

  end


end
