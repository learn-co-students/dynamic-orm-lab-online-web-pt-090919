require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  # Create a downcased, plural table name based on the Class name
  def self.table_name
    # Takes class name, ref by the self keyword, turns it into a str #to_s
    # Downcases the string and then "pluralizes" it, or makes it plural
    self.to_s.downcase.pluralize 
  end
  
  # Return an array of SQL column names
  def self.column_names
    DB[:conn].results_as_hash = true
    
    # Access the name of the table we are querying
    sql = "PRAGMA table_info('#{table_name}')"
    
    table_info = DB[:conn].execute(sql)
    table_info.map{ |row| row["name"] }.compact
    
    # columne_names = []
    # #Iterate over resulting array of hashes to collect just name of each column
    # table_info.each do |row|
    #   column_names << row["name"]
    # end
    
    # # Get rid of nil values
    # # Student.column_names=> ["id", "name", "grade"]
    # return column_names.compact 
  end
  
  def initialize(options={}) #Default to empty hash
    options.each do |property, value|
      self.send("#{property}=", value)
    end
    #=> e.g. {:id=>nil, :name=>"Sam", :grade=>11}
  end
  
  # Return table name when called on an instance of Student
  def table_name_for_insert
    self.class.table_name
  end
  
  # Return abstract column names when called on an instance of Student
  def col_names_for_insert 
    self.class.column_names.delete_if { |col| col == "id"}.join(", ") #=> "name, grade"
  end
  
  # Format column names to be used in a SQL statement
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
       # push return value of invoking a method via the #send, unless value is nil (id before saved)
       # each ind. value enclosed in single ' ' inside string
      values << "'#{send(col_name)}'" unless send(col_name).nil?

    end
    values.join(", ") #return value wrapped in string => "'Sam', '11'"
  end
  
  # Save the student to the db
  def save
    DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})")
    
    self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end
  
  # Execute SQL to find a row by name
  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
    DB[:conn].execute(sql, name)
  end
  
  # Execute SQL to find a row by the attr passed into the method
  def self.find_by(attribute)
    # attribute => {name: "Susan"} -> convert key from symbol to string for SQL
    sql = "SELECT * FROM #{self.table_name} WHERE #{attribute.keys.first.to_s} = ?"
    DB[:conn].execute(sql, attribute.values.first)
  end
end