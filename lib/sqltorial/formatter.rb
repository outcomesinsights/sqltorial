#require 'anbt-sql-formatter/formatter'
#require 'anbt-sql-formatter/rule'

module SQLtorial
  class Formatter
    #attr :formatter

    def initialize
=begin
      rule = AnbtSql::Rule.new

      rule.keyword = AnbtSql::Rule::KEYWORD_UPPER_CASE

      # User defined additional functions:
      %w(stored parquet broadcast).each{|func_name|
        rule.function_names << func_name.upcase
      }

      rule.indent_string = "    "

      @formatter = AnbtSql::Formatter.new(rule)
=end
    end

    def format(file)
      #formatter.format(src)
      @formatted ||= `pg_format #{file}`
      #@formatted ||= `cat #{file} | anbt-sql-formatter`
      #@formatted ||= `cat #{file} | py_format`
      #file.read
    end
  end
end
