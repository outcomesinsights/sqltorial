require 'sqltorial'
require_relative 'query_to_md'
require_relative 'formatter'

module SQLtorial
  WHITESPACE_REGEX = /^\s*--/
  class SqlToExample
    attr :file, :db, :number, :options
    def initialize(file, db, options = {})
      @file = file
      @db = db
      @options = options
      if options[:no_auto_numbering]
        @number = options[:suggested_number] || get_number
      else
        @number = get_number
      end
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
      @queries ||= formatted_lines.slice_before { |l| l =~ /;$/ }
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
      lines = query.dup.map(&:chomp)
      prose_lines = []
      lines.shift if lines.first.strip == ';'
      lines.shift while lines.first && lines.first.strip.empty?
      prose_lines << lines.shift.sub(WHITESPACE_REGEX, '').sub(/^\s*$/, "\n\n") while lines.first && (lines.first =~ WHITESPACE_REGEX || lines.first.empty?)
      directives, prose_lines = prose_lines.partition { |line| Directive.match(line) }
      prose_lines = prose_lines.map { |l| l.sub(/^\s/, '') }
      [prose_lines.join("\n"), process_directives(directives), lines.join("\n")]
    end

    def get_number
      @number ||= file.basename.to_s.to_i
    end

    def to_str(opts = {})
      opts = options.merge(opts.merge(include_results: true))
      hash = {}
      queries.each_with_index do |query, index|
        prose, directives, sql = make_prose_directives_and_query(query)

        begin
          if is_create(sql)
            hash[sql] = [prose, create_to_md(opts, sql, directives)];
            next
          elsif is_passthru(sql)
            execute(sql, opts)
            hash[sql] = [prose, nil];
            next
          end
          hash[sql] = [prose, query_to_md(opts, sql, directives)]
        rescue
          puts sql
          puts $!.message
          puts $!.backtrace.join("\n")
        end
      end
      parts = []
      parts << "# Example #{number}: #{title}\n"
      part_num = 0
      parts += hash.map do |key, value|
        arr = [value.first]
        if key && !key.empty?
          part_num += 1
          arr << "#### Query #{number}.#{part_num}"
          arr << ""
          arr << "```sql\n#{key + ";"}\n```"
        end
        arr << value.last
        arr.join("\n\n")
      end
      parts.join("\n\n") + "\n\n"
    end

    private
    def process_directives(directives)
      directives.map do |line|
        Directive.from_line(line)
      end
    end

    def get_title_and_formatted_lines
      all_lines = formatted.gsub(";", "\n;").split("\n")
      title_line = all_lines.shift
      [title_line, all_lines]
    end

    def is_create(sql)
      sql =~ /^\s*create/i
    end

    def is_drop(sql)
      sql =~ /^\s*drop/i
    end

    def is_use(sql)
      sql =~ /^\s*use/i
    end

    def is_compute(sql)
      sql =~ /^\s*compute\s*stats/i
    end

    def is_passthru(sql)
      is_drop(sql) || is_use(sql) || is_compute(sql)
    end

    def execute(sql, opts)
      db.execute(sql) if opts[:include_results]
    end

    def create_to_md(opts, sql, directives)
      return nil unless opts[:include_results]
      table_name = /create\s*(?:temp)?\s*(?:table|view)(?:\s*if\s*not\s*exists)?\s*(\S+)/i.match(sql)[1]
      execute("DROP TABLE IF EXISTS #{table_name}", opts) if options[:drop_it]
      execute(sql, opts)
      execute("COMPUTE STATS #{table_name}", opts)
      table_name.gsub!('.', '__')
      QueryToMD.new(db[table_name.to_sym], directives).to_md
    end

    def query_to_md(opts, sql, directives)
      return nil unless opts[:include_results]
      return nil if sql.empty?
      QueryToMD.new(db[sql.sub(';', '')], directives, opts).to_md
    end
  end
end
