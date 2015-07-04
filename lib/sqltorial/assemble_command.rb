require_relative 'sql_to_example'
require 'pathname'

module SQLtorial
  class AssembleCommand < ::Escort::ActionCommand::Base
    def execute
      Dir.chdir(arguments.first || ".") do
        preface = Pathname.new(global_options[:preface]) if global_options[:preface]
        Escort::Logger.output.puts global_options.inspect
        File.open(global_options[:output], 'w') do |f|
          f.puts preface.read if preface && preface.exist?
          f.puts(Pathname.glob('*.sql').map do |file|
            SqlToExample.new(file).to_str(!global_options[:no_results])
          end.join("\n\n"))
        end
      end
    end
  end
end
