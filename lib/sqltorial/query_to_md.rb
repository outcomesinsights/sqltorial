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
      @row_limit ||= all.length
    end

    def to_md
      return "No results found." if all.empty?
      output = []
      if all.length > row_limit
        output << "Found #{all.length} results.  Displaying first #{row_limit}."
        output << ""
      end
      output << tableize(all.first.keys + additional_headers)
      output << tableize(orientations_for(all))
      output_rows.each do |row|
        output << tableize(process(row.values))
      end
      output.join("\n") + "\n\n"
    end

    def all
      @all ||= query.from_self.all
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

    def process(columns)
      @processor ||= make_processors(columns)
      @processor.map.with_index do |processor, index|
        value = columns[index]
        if processor
          processor.call(value)
        else
          value
        end
      end
    end

    def make_processors(columns)
      columns.map do |column|
        puts column.class
        case column
        when Float, BigDecimal
          Proc.new do |column|
            sprintf("%.02f", column)
          end
        when Numeric, Fixnum
          Proc.new do |column|
            commatize(column.to_s)
          end
        else
          Proc.new do |column|
            column.to_s.chomp
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

    def commatize(str)
      return str unless str =~ /^\d+$/
      str.reverse.chars.each_slice(3).map(&:join).join(',').reverse
    end
  end
end
