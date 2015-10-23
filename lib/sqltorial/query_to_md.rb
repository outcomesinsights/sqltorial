require_relative 'query_cache'

module SQLtorial
  class QueryToMD
    attr :validation_directives, :other_directives
    attr_accessor :query, :row_limit
    def initialize(query, directives, row_limit = 10)
      @query = query
      @validation_directives, @other_directives = directives.partition { |d| d.respond_to?(:validate) }
      @row_limit = row_limit
      @other_directives.each do |directive|
        directive.alter(self)
      end
    end

    def row_limit
      @row_limit ||= count
    end

    def to_md
      cache.to_md
    end

    def get_md
      return "**No results found.**" if all.empty?
      output = []
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
      output.join("\n") + "\n\n"
    end

    def count
      @count ||= query.from_self.count
    end

    def all
      @all ||= begin
        q = query.from_self
        q = q.limit(row_limit)
        q.all
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
      output_rows.first.map do |name, column|
        if name.to_s =~ /_?id(_|$)/
          Proc.new do |column|
            column.to_s.chomp
          end
        else
          case column
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
      @cache ||= QueryCache.new(self)
    end
  end
end
