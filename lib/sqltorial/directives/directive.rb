module SQLtorial
  class Directive
    class << self
      def register(directive_klass)
        (@@directives ||= []) << directive_klass
      end

      def match(line)
        @@directives.any? do |directive_klass|
          directive_klass.regexp.match(line)
        end
      end

      def from_line(line)
        @@directives.each do |directive_klass|
          return directive_klass.new(line) if directive_klass.regexp.match(line)
        end
      end
    end
  end
end

