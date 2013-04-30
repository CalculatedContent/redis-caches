$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'redis'
require 'redis-namespace'
require 'redis-caches/version'
require 'redis-caches/cache_name'

module RedisCaches
  describe "cache_name"  do

  # redis should be running locally

    it "should  monkeypatch redis namespace " do
      @redis = Redis::Namespace.new("cache", :redis => Redis.new)
      @redis.namespace.should eq "cache"
    end
    
    
     it "should  complain if redis is not a namespace " do
      @redis =  Redis.new
      expect { @redis.namespace }.to raise_error
    end
    

  end
  
end