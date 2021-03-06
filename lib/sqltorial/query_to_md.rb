require_relative 'query_cache'
require 'facets/time/elapse'

module SQLtorial
  class QueryToMD
    attr :validation_directives, :other_directives
    attr_accessor :query, :row_limit, :options
    def initialize(query, directives, options = {})
      @query = query
      @validation_directives, @other_directives = directives.partition { |d| d.respond_to?(:validate) }
      @row_limit = options.fetch(:row_limit, 10)
      @options = options
      @other_directives.each do |directive|
        directive.alter(self)
      end
    end

    def to_md
      cache.to_md
    end

    def get_md
      output = get_output
      output.join("\n") + "\n***\n"
    end

    def get_output
      output = []
      output << "*Query ran in #{time_elapsed}.*\n" if time_elapsed

      if all.empty?
        output << "**No results found.**"
        return output
      end

      output << "Found #{commatize(count)} results."
      if count > row_limit
        output.last << "  Displaying first #{commatize(row_limit)}."
      end
      output << ""
      output << tableize(all.first.keys + additional_headers)
      output << tableize(orientations_for(all))
      output_rows.each do |row|
        output << tableize(process(row.values))
      end
      output
    rescue
      puts "Query failed!"
      puts query
      puts $!.message
      puts $!.backtrace.join("\n")
      output = ["**Query Failed To Complete**"]
    end

    def count
      @count ||= query.from_self.count
    end

    def time_elapsed
      @elapsed_time || all
      return nil unless options[:report_times] && @elapsed_time
      t = @elapsed_time
      ("%02dd%02dh%02dm%02ds" % [t/86400, t/3600%24, t/60%60, t%60]).gsub(/00[^s]/, '')
    end

    def all
      @all ||= begin
        results = nil
        @elapsed_time = Time.elapse do
          results = get_all
        end
        results
      end
    end

    def get_all
      unless row_limit
        self.row_limit = count
        return query.all
      end

      if query.db.database_type == :impala
        sql = query.sql.gsub(';', '')
        sql << " limit #{row_limit}"
        query.db[sql].all
      else
        query.limit(row_limit).all
      end
    end

    def additional_headers
      validation_directives.empty? ? [] : [:valid_row]
    end

    def output_rows
      rows = all[0...row_limit]
      return rows if validation_directives.empty?

      rows.map do |row|
        row[:valid_row] = validation_directives.all? { |d| d.validate(row) } ? 'Y' : 'N'
        row
      end
    end

    def tableize(columns)
      "| #{columns.join(" | ")} |"
    end

    def processors
      @processors ||= make_processors
    end

    def process(columns)
      processors.map.with_index do |processor, index|
        value = columns[index]
        if processor
          processor.call(value)
        else
          value
        end
      end
    end

    def make_processors
      output_rows.first.map do |name, col|
        if name.to_s =~ /_?id(_|$)/
          Proc.new do |column|
            column.to_s.chomp
          end
        else
          case col
          when Float, BigDecimal
            Proc.new do |column|
              column ? commatize(sprintf("%.02f", column)) : nil
            end
          when Numeric, Fixnum
            Proc.new do |column|
              column ? commatize(column.to_s) : nil
            end
          else
            Proc.new do |column|
              column.to_s.chomp
            end
          end
        end
      end
    end

    def orientations_for(dataset)
      widths = widths_for(dataset)
      dataset.first.map.with_index do |(_, value), index|
        case value
        when Numeric, Fixnum, Float
          widths[index][-1] = ":"
        else
          widths[index][0] = ":"
        end
        widths[index]
      end
    end

    def widths_for(dataset)
      widths = [0] * dataset.first.length
      dataset.each do |row|
        widths = row.map.with_index do |value, index|
          [value.to_s.length, widths[index]].max
        end
      end
      widths.map { |width| '-' * width }
    end

    def commatize(input)
      str = input.to_s
      return str unless str =~ /^[\d.]+$/
      str, dec = str.split('.')
      commaed = str.reverse.chars.each_slice(3).map(&:join).join(',').reverse
      commaed << ".#{dec}" if dec and !dec.empty?
      commaed
    end

    def cache
      @cache ||= QueryCache.new(options[:cache], self)
    end
  end
end
