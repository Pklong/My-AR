require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    self.foreign_key = options[:foreign_key] || "#{name}Id".underscore.to_sym
    self.class_name = options[:class_name] || name.to_s.singularize.camelcase
    self.primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self.foreign_key = options[:foreign_key] || "#{self_class_name}Id".underscore.to_sym
    self.class_name = options[:class_name] || name.to_s.singularize.camelcase
    self.primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    define_method(name) do
      fk = send(options.foreign_key)
      pk = options.primary_key
      options.model_class.where({pk => fk}).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, options[:class_name], options)
    p options
    define_method(name) do
      fk = send(options.foreign_key)
      pk = options.primary_key
      options.model_class.where({fk => pk}).first
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
