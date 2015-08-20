module SQLtorial
  class ValidColumnDirective
    REGEXP = /^ DIRECTIVE:\s*(\S+)\s+(\S+)\s+(.+)/
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
  end
  Directive.register(AllDirective)
end
