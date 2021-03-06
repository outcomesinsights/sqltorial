require_relative 'sql_to_example'
require_relative 'cache'
require 'sequelizer'
require 'facets/pathname/chdir'
require 'listen'
require "fileutils"

module SQLtorial
  class AssembleCommand < ::Escort::ActionCommand::Base
    include Sequelizer
    def execute
      global_options[:watch] ? watch : process
    end

    def watch
      listener = Listen.to(dir) do |modified, added, removed|
        process
       end
      listener.only(/\.sql$/)
      listener.start
      sleep while listener.processing?
    end

    def process
      cache.remove if global_options[:ignore_cache]
      opts = {
        cache: cache
      }
      db.run(global_options[:setup]) if global_options[:setup]
      process_dir.chdir do
        preface = Pathname.new(global_options[:preface]) if global_options[:preface]
        File.open(global_options[:output], 'w') do |f|
          f.puts preface.read if preface && preface.exist?
          files.each.with_index do |file, index|
            Escort::Logger.output.puts "Examplizing #{file.to_s}"
            example = SqlToExample.new(file, db, opts.merge(global_options.merge(suggested_number: index + 1)))
            f.puts example.to_str(global_options)
            f.puts "\n\n"
            f.flush
          end
        end
      end
    end

    def process_dir
      @process_dir = path.directory? ? path : Pathname.pwd
    end

    def dir
      @dir ||= path.directory? ? path : path.dirname
    end

    def path
      @path ||= Pathname.new(arguments.first || ".")
    end

    def files
      path.directory? ? Pathname.glob('*.sql').sort : files_from_file
    end

    def files_from_file
      path.readlines.map(&:chomp!).select { |l| l !~ /^\s*#/ && !l.empty? }.map do |file_name|
        Pathname.new(file_name)
      end
    end

    def cache
      @cache ||= Cache.new(db, global_options)
    end
  end
end
