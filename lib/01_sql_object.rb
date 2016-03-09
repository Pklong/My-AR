require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL).first.map(&:to_sym)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    SQL
  end

  def self.finalize!
    columns.each do |column|

      define_method(column) do
         attributes[column]
       end

      define_method("#{column}=") do |val|
        attributes[column] = val
      end
    end

  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self}".tableize
  end

  def self.all
    parse_all(DBConnection.instance.execute(<<-SQL))
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    SQL
  end

  def self.parse_all(results)
    results.map do |result|
      new(result)
    end
  end

  def self.find(id)
    parse_all(DBConnection.instance.execute(<<-SQL, id)).first
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    WHERE
      #{table_name}.id = ?
    SQL
  end

  def initialize(params = {})
    params.each do |key, val|
      attr_name = key.to_sym
      unless self.class.columns.include?(attr_name)
        raise "unknown attribute '#{attr_name}'"
      else
        self.send("#{attr_name}=", val)
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |val| send(val) }
  end

  def insert
    col_names = self.class.columns.join(", ")
    question_marks = (["?"] * self.class.columns.length).join(", ")
    DBConnection.instance.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_vals = self.class.columns.map do |attr_name|
      "#{attr_name} = ?"
    end.join(", ")

    DBConnection.instance.execute(<<-SQL, *attribute_values, self.id)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_vals}
    WHERE
      #{self.class.table_name}.id = ?

    SQL
  end

  def save
    self.id ? update : insert
  end
end
