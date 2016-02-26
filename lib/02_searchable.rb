require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.map {|k, v| "#{k} = #{v}"}.join("AND")

    DBConnection.instance.execute(<<-SQL, *attribute_values)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{where_line}

    SQL
  end
end

class SQLObject
  # Mixin Searchable here...
end
