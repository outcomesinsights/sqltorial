require 'sequelizer'
require_relative 'query_to_md'
require_relative 'directive'

module SQLtorial
  class SqlToExample
    include Sequelizer
    attr :file
    def initialize(file)
      @file = file
    end

    def formatted
      #@formatted ||= `pg_format #{file}`
      @formatted ||= `cat #{file} | anbt-sql-formatter`
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
      @title ||= title_line.gsub(/^\s*-+\s*/, '')
    end

    def make_prose_directives_and_query(query)
      lines = query.dup
      prose_lines = []
      lines.shift while lines.first.empty?
      prose_lines << lines.shift.sub(/^\s*-+\s*/, ' ').chomp.sub(/^ $/, "\n\n") while lines.first =~ /^(-+|$)/
      directives, prose_lines = prose_lines.partition { |line| Directive.match(line) }
      [prose_lines.join(''), process_directives(directives), lines.join("\n")]
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
            create(sql)
            hash[sql] = [prose, nil];
            next
          end
          hash[sql] = [prose, include_results ? QueryToMD.new(db[sql.sub(';', '')], directives).to_md : nil]
        rescue
          puts sql
          puts $!.message
          puts $!.backtrace.join("\n")
          gets
        end
      end
      parts = []
      parts << "## Example #{number}: #{title}\n"
      parts += hash.map do |key, value|
        "#{value.first}\n\n```sql\n#{key}\n```\n\n#{value.last}\n"
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
      all_lines = formatted.split("\n")
      title_line = all_lines.shift
      [title_line, all_lines]
    end

    def is_create(sql)
      sql =~ /^create/i
    end

    def create(sql)
      db.execute(sql)
    end
  end
end
