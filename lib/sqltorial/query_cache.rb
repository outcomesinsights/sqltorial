require 'digest'

module SQLtorial
  class QueryCache
    attr_reader :query_to_md

    def initialize(query_to_md)
      @query_to_md = query_to_md
    end

    def to_md
      unless cache_file.exist?
        make_cache_file
      end
      cache_file.read
    end

    def make_cache_file
      cache_file.dirname.mkpath
      cache_file.write(query_to_md.get_md)
    end

    def cache_file
      @cache_file ||= Pathname.pwd + '.sqltorial_cache' + cache_file_name
    end

    def cache_file_name
      @cache_file_name ||= Digest::SHA256.hexdigest("#{input_str}") + ".md"
    end

    def input_str
      @input_str ||= %w(query row_limit validation_directives other_directives).inject("") do |s, meth|
        s + query_to_md.send(meth).inspect
      end
    end
  end
end
