
module SQLtorial
  class QueryCache
    attr_reader :query_to_md, :cache

    def initialize(cache, query_to_md, options = {})
      @cache = cache
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
      @cache_file ||= cache.cache_file_path(cache.hash_it(input_str) + ".md")
    end

    def input_str
      @input_str ||= %w(query row_limit validation_directives other_directives).inject("") do |s, meth|
        s + query_to_md.send(meth).inspect
      end
    end

  end
end
