$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'redis'
require 'redis-namespace'
require 'redis-caches/version'
require 'redis-caches/s3_cache'

module RedisCaches
  describe  RedisCaches::S3Cache  do
    
  # redis.s3....

  # redis should be running locally
    before(:each) do
      @redis = Redis::Namespace.new(RedisCaches::S3Cache::DEFAULT_NAMESPACE, :redis => Redis.new)
      @redis.s3_init
    end

    after(:each) do
      @redis.flushdb
    end

    it "should recognize monkeypatched namespace name" do
      @redis.s3.namespace.should eq RedisCaches::S3Cache::DEFAULT_NAMESPACE
    end
    
    it "should set default bucket " do
      @redis.s3.bucket.should eq RedisCaches::S3Cache::DEFAULT_NAMESPACE
    end
    
    it "should set keep_dir default using namespace " do
      @redis.s3.keep_dir.should eq "./#{@redis.s3.namespace}"
    end
    
    it "should not set keep_tmp_files?  " do
      @redis.s3.keep_tmp_files?.should be false
    end
    
    
    # "#{@s3name}.#{@worker_id}.#{timestamp}.jsons.gz".gsub(/:/,"-")
    it "should create a tmp filename" do
      @redis.s3.tmpfile.should match /#{@redis.s3.name}.#{@redis.s3.worker_id}.*.jsons.gz/
    end

    # "s3://#{bucket}/#{folder}/#{tmpfile}"    
    it "should create an s3 file name using the bucket and folder" do
       @redis.s3.aws_filename.should match /#{@redis.s3.bucket}\/#{@redis.s3.folder}.*.jsons.gz/
    end

    it "should create an timestamp that is a valid bucket name part" do
       @redis.s3.timestamp.should_not match /[:\\]/
    end
    
    it "should have an s3cmd for testing" do
       @redis.s3.s3cmd.should eq RedisCaches::S3Cache::S3CMD
       @redis.s3.s3cmd="echo"
       @redis.s3.s3cmd.should eq "echo"
    end
    

    it "should wipe the keys for save! " do       
      @redis.s3.s3cmd="echo"
      @redis.incr "count"
      @redis.s3.save!
      @redis.keys.should be_empty     
    end
    
    it "should not wipe the keys for save " do       
      @redis.s3.s3cmd="echo"
      @redis.incr "count"
      @redis.s3.save
      @redis.keys.size.should eq 1
    end
    
    it 'should  allow setting keep_tmp_file' do
      @redis.s3.should respond_to(:keep_tmp_files?)
      @redis.s3.keep_tmp_files = true
      @redis.s3.keep_tmp_files?.should be true
    end
    
    # not my favorite way to test this...but
    it 'should  the keep_tmp_file, and be able to read it back' do
      FileUtils.rm_rf(@redis.s3.save_dir)
      
      @redis.s3.keep_tmp_files = true
      @redis.s3.s3cmd="echo"
      @redis.incr "count"
      keys = @redis.s3.save!
      
      keys.size.should eq 1
      @redis.keys.size.should eq 0
      
      Dir.exists?(@redis.s3.save_dir).should be true
      Dir.entries(@redis.s3.save_dir).each do |filename| 
        next unless filename =~ /.*jsons.gz/
        @redis.s3.load_from_file(File.join(@redis.s3.save_dir,filename))
      end
      
       @redis.keys.size.should eq 1
       @redis['count'].should eq "1"
      
      FileUtils.rm_rf(@redis.s3.save_dir)
    end
    
    it 'should not keep a tmp file if not specified' do      
      @redis.s3.s3cmd="echo"
      @redis.incr "count"
      keys = @redis.s3.save!
      
      keys.size.should eq 1
      @redis.keys.size.should eq 0
      
      Dir.exists?(@redis.s3.save_dir).should be false
    end
    
    
    it 'should not save if keys are empty' do
        @redis.s3.keep_tmp_files = true
        keys = @redis.s3.save!  
        keys.size.should eq 0 
        Dir.exists?(@redis.s3.save_dir).should be true
        Dir.entries(@redis.s3.save_dir).size.should be 2

        FileUtils.rm_rf(@redis.s3.save_dir)
    end
    
    # # assumes s3cmd spec-tests bucket is set up
    # # this is awful...really need fog
    # it 'should write a file to a tmp s3 bucket ' do
#       
      # bucket = "spec-tests"
      # @redis.s3.bucket = bucket
      # @redis.s3.bucket.should eq bucket
#       
      # @redis.incr "count"
      # keys = @redis.s3.save!
#       
    # end
    
  end

end

#TODO:  fix the spec to support flatten on/off
#TODO:  add fog version
