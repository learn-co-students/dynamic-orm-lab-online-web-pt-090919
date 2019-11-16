require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  
  def self.table_name
    self.to_s.downcase.pluralize
  end
  
  def self.column_names
    #DB[:conn].results_as_hash = true
   
    sql = "PRAGMA table_info('#{table_name}')"
   
    table_info = DB[:conn].execute(sql)
    column_names = []
   
    table_info.each do |column, value|
      column_names << column["name"]
    end
   
    column_names.compact
  end
  
  # self.column_names.each do |col_name|
  #   attr_accessor col_name.to_sym
  #   binding.pry
  # end
  
  def initialize(attrs = {})
    attrs.each do |key, value|
      self.class.attr_accessor key.to_sym
      self.send("#{key}=", value)
    end
  end
  
  def table_name_for_insert
    self.class.table_name
  end
  
  def col_names_for_insert
    self.class.column_names.select{|col_name| col_name != "id"}.join(", ")
  end
  
  def values_for_insert
    self.col_names_for_insert.split(", ").map{
      |col_name| "'#{self.send(col_name)}'"
    }.join(", ")
  end
  
  def save
    DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})")
   
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end
  
  def self.find_by_name(name)
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = '#{name}'")
  end
  
  def self.find_by(kv_pair)
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{kv_pair.keys[0]} = '#{kv_pair.values[0]}'")
  end
  
end