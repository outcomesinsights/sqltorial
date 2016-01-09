require 'digest'

module SQLtorial
  class Cache
    attr :db

    def initialize(db)
      @db = db
    end

    def cache_file_path(str)
      cache_dir + str
    end

    def remove
      cache_dir.rmtree if cache_dir.exist?
    end

    def cache_dir
      @cache_dir ||= Pathname.pwd + '.sqltorial_cache' + hash_it(db.opts.inspect)
    end

    def hash_it(str)
      Digest::SHA256.hexdigest("#{str}")
    end
  end
end
