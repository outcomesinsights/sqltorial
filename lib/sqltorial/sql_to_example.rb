require 'sqltorial'
require_relative 'query_to_md'
require_relative 'formatter'

module SQLtorial
  WHITESPACE_REGEX = /^\s*--/
  class SqlToExample
    attr :file, :db
    def initialize(file, db, number)
      @file = file
      @db = db
      @number = number
    end

    def formatted
      @formatted ||= formatter.format(file)
    end

    def formatter
      @formatter ||= Formatter.new
    end

    def formatted_lines
      if @formatted_lines.nil?
        @title_line, @formatted_lines = get_title_and_formatted_lines
      end
      @formatted_lines
    end

    def queries
      @queries ||= formatted_lines.slice_after { |l| l =~ /;$/ }
    end

    def title_line
      if @title_line.nil?
        @title_line, @formatted_lines = get_title_and_formatted_lines
      end
      @title_line
    end

    def title
      @title ||= title_line.gsub(WHITESPACE_REGEX, '')
    end

    def make_prose_directives_and_query(query)
      lines = query.dup
      prose_lines = []
      lines.shift while lines.first.strip.empty?
      prose_lines << lines.shift.sub(WHITESPACE_REGEX, ' ').sub(/^\s*$/, "\n\n") while lines.first && (lines.first =~ WHITESPACE_REGEX || lines.first.empty?)
      directives, prose_lines = prose_lines.partition { |line| Directive.match(line) }
      [prose_lines.join(''), process_directives(directives), lines.join]
    end

    def number
      @number ||= file.basename.to_s.to_i
    end

    def to_str(include_results = true)
      hash = {}
      queries.each_with_index do |query, index|
        prose, directives, sql = make_prose_directives_and_query(query)

        begin
          if is_create(sql)
            execute(sql, include_results)
            hash[sql] = [prose, create_to_md(include_results, sql, directives)];
            next
          elsif is_drop(sql)
            execute(sql, include_results)
            hash[sql] = [prose, nil];
            next
          end
          hash[sql] = [prose, query_to_md(include_results, sql, directives)]
        rescue
          puts sql
          puts $!.message
          puts $!.backtrace.join("\n")
        end
      end
      parts = []
      parts << "## Example #{number}: #{title}\n"
      part_num = 0
      parts += hash.map do |key, value|
        arr = [value.first]
        if key && !key.empty?
          part_num += 1
          arr << "**Query #{number}.#{part_num}**"
          arr << "```sql\n#{key}\n```"
        end
        arr << value.last
        arr.join("\n\n")
      end
      parts.join("\n") + "\n\n"
    end

    private
    def process_directives(directives)
      directives.map do |line|
        Directive.from_line(line)
      end
    end

    def get_title_and_formatted_lines
      all_lines = formatted.split("\n").map { |l| l += "\n" }
      title_line = all_lines.shift
      [title_line, all_lines]
    end

    def is_create(sql)
      sql =~ /^\s*create/i
    end

    def is_drop(sql)
      sql =~ /^\s*drop/i
    end

    def execute(sql, include_results)
      db.execute(sql) if include_results
    end

    def create_to_md(include_results, sql, directives)
      return nil unless include_results
      table_name = /create\s*(?:temp)?\s*(?:table|view)\s*(\S+)/i.match(sql)[1].gsub('.', '__')
      QueryToMD.new(db[table_name.to_sym], directives).to_md
    end

    def query_to_md(include_results, sql, directives)
      return nil unless include_results
      return nil if sql.empty?
      QueryToMD.new(db[sql.sub(';', '')], directives).to_md
    end
  end
end
