require 'digest'

module SQLtorial
  class Cache
    attr :db, :options

    def initialize(db, options)
      @db = db
      @options = options.dup
    end

    def cache_file_path(str)
      cache_dir + str
    end

    def remove
      cache_dir.rmtree if cache_dir.exist?
    end

    def cache_dir
      @cache_dir ||= Pathname.pwd + '.sqltorial_cache' + hash_it(hash_fodder)
    end

    def hash_fodder
      db.opts.inspect + hashable_options.inspect
    end

    def hashable_options
      opts = options.dup
      %w(ignore_cache output watch preface).map(&:to_sym).each do |key|
        opts.delete(key)
      end
      opts
    end

    def hash_it(str)
      Digest::SHA256.hexdigest("#{str}")
    end
  end
end
