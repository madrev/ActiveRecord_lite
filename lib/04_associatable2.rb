require_relative '03_associatable'

module Associatable

  def has_one_through(name, through_name, source_name)

    define_method(name) do
      
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]
      through_table = through_options.table_name
      source_table = source_options.table_name
      through_id = self.send(through_name.to_s).id

      result = DBConnection.execute(<<-SQL, through_id)
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table}
        ON
          #{through_table}.#{through_options.primary_key} =
          #{source_table}.#{source_options.primary_key}
        WHERE
          #{through_table}.id = ?
      SQL
      source_options.model_class.parse_all(result).first
    end
  end

end
