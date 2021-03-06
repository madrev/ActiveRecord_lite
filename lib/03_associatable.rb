require_relative '02_searchable'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || "#{name}_id".to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.camelcase
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] || "#{self_class_name.downcase}_id".to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.singularize.camelcase
  end
end

module Associatable
  def belongs_to(name, options = {})
    options_obj = BelongsToOptions.new(name, options)

    define_method(name) do
      fkey_value = self.send(options_obj.foreign_key)
      pkey = options_obj.primary_key
      options_obj.model_class.where(pkey => fkey_value).first
    end
    self.assoc_options[name] = options_obj
  end

  def has_many(name, options = {})
    options_obj = HasManyOptions.new(name, self.to_s, options)

    define_method(name) do
      pkey_value = self.send(options_obj.primary_key)
      fkey = options_obj.foreign_key
      options_obj.model_class.where(fkey => pkey_value)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
