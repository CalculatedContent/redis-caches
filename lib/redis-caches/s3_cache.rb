require 'json'
require 'zlib'
require 'redis'
require 'redis-caches/cache_name'
require 'redis-namespace'
require 'tmpdir'

#TODO: migrate to fog

class Redis
  
  class Namespace
    
    attr_reader :s3
    
    def s3_init(opts={})
      @s3 =  RedisCaches::S3Cache.new(self,opts)
    end

  end
  
end


module RedisCaches
  class S3Cache

    DEFAULT_NAMESPACE = 'cache'
    DEFAULT_BUCKET = 'cache'
    S3CMD = 's3cmd'

    attr_reader :namespace, :worker_id, :bucket, :folder, :name, :save_dir, :s3cmd
    
    def initialize(redis_namespace, opts = {})
      @redis = redis_namespace
      @opts = opts

      @namespace = @redis.namespace || DEFAULT_NAMESPACE
      @worker_id = opts[:worker_id] || Socket.gethostname
      @bucket = opts[:s3_bucket] || DEFAULT_BUCKET
      @folder = namespace.gsub(/:/,"-")
      @name = namespace.gsub(/:/,"-")
      @save_dir = opts[:keep_tmp_files] || "./#{namespace}"
      @keep_tmp_files = !opts[:keep_tmp_files].nil?
      @s3cmd = S3CMD
    end
    
    # for testing
    def s3cmd=(cmd)
      @s3cmd = cmd
    end
    
    def keep_tmp_files=(tf)
      @keep_tmp_files = tf
    end
    
    def bucket=(b)
      @bucket = b
    end

    def close
      @redis.quit
    end

    def keep_tmp_files?
     @keep_tmp_files
    end

    def keep_dir
      @opts[:keep_dir] || "./#{namespace}"
    end

    def timestamp
      Time.now.getutc.to_s.gsub(/\s/,'').gsub(/:/,"-")
    end

    def tmpfile
      "#{name}.#{worker_id}.#{timestamp}.jsons.gz".gsub(/:/,"-")
    end

    def aws_filename
      "s3://#{bucket}/#{folder}/#{tmpfile}"
    end

    def save!
      keys_saved = save()
      delete!(keys_saved)
    end

    # currently assumes all keys are strings or counters
    # TODO:  replace with FOG API or something better
    def save
      keys = []
      FileUtils.mkdir_p keep_dir if keep_tmp_files?
      Dir.mktmpdir do |dir|
        keys, tmpfile = save_to(dir)
        unless keys.empty? then
          cmd = "#{s3cmd} put #{dir}/#{tmpfile} #{aws_filename}"
          system cmd
          FileUtils.mv(File.join(dir,tmpfile), keep_dir) if keep_tmp_files?
        end
      end
      return keys
    end


#TODO:try to unconvert redis json strings , then reparse
# slow but useful
# generally, should just convert any object by type but need this too
# for hash keys

    def save_to(dir=".", flatten=true, key="s3id")
      keys, filename = @redis.keys("*"), tmpfile()
      return [], nil if keys.empty?
      Zlib::GzipWriter.open(File.join(dir,filename)) do |gz|
        keys.each do |k|
          
          line = if flatten then
            begin
              hsh = JSON.parse(@redis[k])
              hsh[key] = k
              hsh.to_json
            rescue JSON::ParserError
              {k => @redis[k]}.to_json 
            end
          else
            {k => @redis[k]}.to_json 
          end
                
          gz.write line
          gz.write "\n"
        end
      end
      return keys, filename
    end

    # this is so dumb...can't ruby redis cli take a giant list of keys?
    def delete!(keys)
      @redis.pipelined do
        keys.each { |k| @redis.del k }
      end
      return keys
    end


    def load_from_file(filename)
      @redis.pipelined do
        Zlib::GzipReader.open(filename) do |gz|
          gz.each do |line|
            hsh = JSON.parse(line.chomp)
            hsh.each_pair { |k,v| @redis[k]=v }
          end
        end
      end

    end

  end
end

