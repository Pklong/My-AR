require_relative 'searchable'
require 'active_support/inflector'


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

  def belongs_to(name, options = {})
    assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      fk = send(options.foreign_key)
      pk = options.primary_key
      options.model_class.where({pk => fk}).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name.to_s, options)
    define_method(name) do
      fk = options.foreign_key
      pk = send(options.primary_key)
      options.model_class.where({fk => pk})
    end
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options

  end
end

def has_one_through(name, through_name, source_name)

  define_method(name) do
    through_options = self.class.assoc_options[through_name]
    source_options =
      through_options.model_class.assoc_options[source_name]

    through_table = through_options.table_name
    through_pk = through_options.primary_key
    through_fk = through_options.foreign_key

    source_table = source_options.table_name
    source_pk = source_options.primary_key
    source_fk = source_options.foreign_key

    through_fk_value = self.send(through_fk)

    source_options.model_class.parse_all(
    DBConnection.execute(<<-SQL, through_fk_value)).first
    SELECT
      #{source_table}.*
    FROM
      #{through_table}
    JOIN
      #{source_table}
    ON
      #{through_table}.#{source_fk} = #{source_table}.#{source_pk}
    WHERE
      #{through_table}.#{through_pk} = ?
    LIMIT
      1
    SQL
  end
end

class SQLObject
  extend Associatable
end
