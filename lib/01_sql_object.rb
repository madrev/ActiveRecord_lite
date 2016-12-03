require_relative 'db_connection'
require 'active_support/inflector'


class SQLObject
  def self.columns
    return @columns if @columns

    arr = DBConnection.execute2(<<-SQL)
      SELECT * FROM #{self.table_name}
    SQL
    @columns = arr.first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column.to_s) { attributes[column] }
      define_method("#{column}=") {|value| attributes[column] = value}
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    self.parse_all(
    DBConnection.execute(<<-SQL)
      SELECT #{self.table_name}.* FROM #{self.table_name}
    SQL
    )
  end

  def self.parse_all(results)
    result = []
    results.each do |attributes|
      instance = self.new(attributes)
      result << instance
    end
    result
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT #{self.table_name}.* FROM #{self.table_name} WHERE id = ?
    SQL
    result.empty? ? nil : self.new(result.first)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      unless self.class.columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      end
      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map {|column| self.send(column.to_sym)}
  end

  def insert
    col_names = self.class.columns.map(&:to_s).join(", ")
    question_marks = Array.new(columns.count){"?"}.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO #{self.class.table_name} (#{col_names})
      VALUES (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_clause = columns.map {|col_name| "#{col_name} = ?"}.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE #{self.class.table_name}
      SET #{set_clause}
      WHERE id = ?
    SQL
  end

  def save
    self.id.nil? ? insert : update
  end

private

  def columns
    self.class.columns
  end

end
