require_relative "directive"

module SQLtorial
  class AllDirective
    REGEXP = /^\s*DIRECTIVE:\s*ALL/
    class << self
      def regexp
        REGEXP
      end
    end

    def initialize(line)
    end

    def alter(query_to_md)
      query_to_md.row_limit = nil
    end

    def inspect
      "ALL"
    end
  end
  Directive.register(AllDirective)
end


