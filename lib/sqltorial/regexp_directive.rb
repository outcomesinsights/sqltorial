require_relative "directive"

module SQLtorial
  class RegexpDirective
    REGEXP = /^ DIRECTIVE:\s*(\S+)\s+(\S+)\s+(.+)/
    class << self
      def regexp
        REGEXP
      end
    end

    attr :column, :op, :matcher
    def initialize(line)
      _, column, op, matcher = REGEXP.match(line).to_a
      @column = column.to_sym
      @op = op
      @matcher = Regexp.new(matcher)
    end

    def validate(result)
      md = matcher.match(result[column])
      op == '=' ? !md.nil? : md.nil?
    end

    def inspect
      [column, op, matcher].join(" ")
    end
  end

  Directive.register(RegexpDirective)
end
