require "hitnmiss"
require "redis"
require "hitnmiss/redis_driver-version"

module Hitnmiss
  class RedisDriver
    include Hitnmiss::Driver::Interface

    def initialize(redis_url)
      @redis = Redis.new(:url => redis_url)
    end

    def set(key, entity)
      value = { value: entity.value }
      value[:updated_at] = internal_timestamp
      value[:fingerprint] = entity.fingerprint if entity.fingerprint
      value[:last_modified] = entity.last_modified if entity.last_modified
      if entity.expiration
        @redis.setex(key, entity.expiration, serialize_value(value))
      else
        @redis.set(key, serialize_value(value))
      end
    end

    def get(key)
      cached_item = @redis.get(key)
      return Hitnmiss::Driver::Miss.new if cached_item.nil?
      deserialized_value = deserialize_value(cached_item)
      Hitnmiss::Driver::Hit.new(deserialized_value[:value], build_hit_keyword_args(deserialized_value))
    end

    def delete(key)
      @redis.del(key)
    end

    def all(keyspace)
      separator = Hitnmiss::Repository::KeyGeneration::KEY_COMPONENT_SEPARATOR
      keys = get_keys("#{keyspace}#{separator}*")
      return [] if keys.empty?
      values = @redis.mget(*keys)
      loaded_values = []
      values.each do |value|
        loaded_values << deserialize_value(value).delete(:value) unless value.nil?
      end
      return loaded_values
    end

    def clear(keyspace)
      separator = Hitnmiss::Repository::KeyGeneration::KEY_COMPONENT_SEPARATOR
      keys = get_keys("#{keyspace}#{separator}*")
      @redis.del(*keys) unless keys.empty?
    end

    private

    def internal_timestamp
      Time.now.utc.iso8601
    end

    def get_keys(pattern)
      keys = []
      @redis.scan_each(match: pattern) do |key|
        keys << key
      end
      return keys
    end

    def deserialize_value(value)
      Marshal.load(value)
    end

    def serialize_value(value)
      Marshal.dump(value)
    end

    def build_hit_keyword_args(cached_entity)
      options = {}
      if cached_entity.has_key?(:fingerprint)
        options[:fingerprint] = cached_entity[:fingerprint]
      end
      if cached_entity.has_key?(:updated_at)
        options[:updated_at] = Time.parse(cached_entity[:updated_at])
      end
      if cached_entity.has_key?(:last_modified)
        options[:last_modified] = cached_entity[:last_modified]
      end
      return **options
    end
  end
end
