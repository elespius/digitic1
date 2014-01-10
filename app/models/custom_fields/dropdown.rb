class Dropdown < CustomField

  # Idea: In the future, if we have other field types with options (like checkbox or radio button)
  # we could move this to subclasses, etc:
  # Dropdown < OptionField < CustomField
  # Checkbox < OptionField < CustomField
  has_many :options, :class_name => "CustomFieldOption", :dependent => :destroy, :foreign_key => 'custom_field_id'
  
  validates_length_of :options, :minimum => 2

  def with_type(&block)
    block.call(:dropdown)
  end

  def selected_option_id_for(listing)
    answer = answer_for(listing)

    if answer
      selected_option = answer.selected_options.first # Select first, dropdown only has one answer
      return selected_option.id
    end
  end

  def option_attributes=(attributes)
    attributes.each { |index, option| options.build(option) }
  end
end
