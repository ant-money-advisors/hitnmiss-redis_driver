require 'spec_helper'

describe "Hitnmiss::RedisDriver" do
  describe ".new" do
    it "constructs an instance of Hitnmiss::RedisDriver" do
      redis_url = double('redis url')
      allow(Redis).to receive(:new)
      driver = ::Hitnmiss::RedisDriver.new(redis_url)
      expect(driver).to be_a(::Hitnmiss::RedisDriver)
    end

    it "creates redis connection" do
      redis_url = "redis://localhost"
      expect(Redis).to receive(:new).with({ :url => redis_url })
      driver = ::Hitnmiss::RedisDriver.new(redis_url)
    end

    it "assigns the created redis connection" do
      redis = double('redis')
      redis_url = double('redis url')
      allow(Redis).to receive(:new).and_return(redis)
      driver = ::Hitnmiss::RedisDriver.new(redis_url)
      expect(driver.instance_variable_get(:@redis)).to eq(redis)
    end
  end

  describe "#set" do
    let(:redis_url) { double('redis url') }
    let(:redis) { double('redis').as_null_object }
    let(:driver) { ::Hitnmiss::RedisDriver.new(redis_url) }

    before do
      allow(Redis).to receive(:new).and_return(redis)
    end

    it 'dumps the value' do
      entity = Hitnmiss::Entity.new('somevalue', expiration: 11)
      expect(driver).to receive(:serialize_value).with({ value: 'somevalue', updated_at: anything })
      driver.set('somekey', entity)
    end

    context 'when given an entity with an expiration' do
      it 'stores the dumped value with the key and ttl' do
        entity = Hitnmiss::Entity.new('somevalue', expiration: 11)
        dumped_value = double('dumped some value')
        allow(driver).to receive(:serialize_value).with({ value: 'somevalue', updated_at: anything })
          .and_return(dumped_value)
        expect(redis).to receive(:setex).with('somekey', 11, dumped_value)
        driver.set('somekey', entity)
      end
    end

    context 'when given an entity without an expiration' do
      it 'stores the dumped value with the key' do
        entity = Hitnmiss::Entity.new('somevalue')
        dumped_value = double('dumped some value')
        allow(driver).to receive(:serialize_value).with({ value: 'somevalue', updated_at: anything })
          .and_return(dumped_value)
        expect(redis).to receive(:set).with('somekey', dumped_value)
        driver.set('somekey', entity)
      end
    end
  end

  describe "#get" do
    it "attempts to get the value from redis" do
      redis_url = double('redis url')
      redis = double('redis')
      allow(Redis).to receive(:new).and_return(redis)
      driver = ::Hitnmiss::RedisDriver.new(redis_url)

      expect(redis).to receive(:get).with('somekey')

      driver.get('somekey')
    end

    context "when a value has NOT been stored at the given key" do
      it "returns Hitnmiss::Driver::Miss" do
        redis_url = double('redis url')
        redis = double('redis')
        allow(Redis).to receive(:new).and_return(redis)
        driver = ::Hitnmiss::RedisDriver.new(redis_url)

        allow(redis).to receive(:get).and_return(nil)

        expect(driver.get('somekey')).to be_a Hitnmiss::Driver::Miss
      end
    end

    context "when a value has been stored at the given key" do
      it 'loads the value' do
        redis_url = double('redis url')
        redis = double('redis')
        value = double('value')
        allow(Redis).to receive(:new).and_return(redis)
        driver = ::Hitnmiss::RedisDriver.new(redis_url)

        allow(redis).to receive(:get).and_return(value)
        expect(driver).to receive(:deserialize_value).with(value)
          .and_return({ value: double })
        driver.get('somekey')
      end

      it 'creates a Hitnmiss::Driver::Hit with the value' do
        redis_url = double('redis url')
        redis = double('redis')
        value = double('value')
        allow(Redis).to receive(:new).and_return(redis)
        driver = ::Hitnmiss::RedisDriver.new(redis_url)

        allow(redis).to receive(:get).and_return(value)
        loaded_value = double('loaded some value')
        allow(driver).to receive(:deserialize_value).with(value)
          .and_return({ value: loaded_value })
        expect(Hitnmiss::Driver::Hit).to receive(:new).with(loaded_value, {})
        driver.get('somekey')
      end

      it 'returns the Hitnmiss::Driver::Hit' do
        redis_url = double('redis url')
        redis = double('redis')
        value = double('value')
        allow(Redis).to receive(:new).and_return(redis)
        driver = ::Hitnmiss::RedisDriver.new(redis_url)

        allow(redis).to receive(:get).and_return(value)
        loaded_value = double('loaded some value')
        allow(driver).to receive(:deserialize_value).with(value)
          .and_return({ value: loaded_value })
        hit = double('hit')
        allow(Hitnmiss::Driver::Hit).to receive(:new).with(loaded_value, {})
          .and_return(hit)
        expect(driver.get('somekey')).to eq(hit)
      end
    end
  end

  describe '#delete' do
    it 'deletes the key from redis' do
      redis_url = double('redis url')
      redis = double('redis')
      allow(Redis).to receive(:new).and_return(redis)
      driver = ::Hitnmiss::RedisDriver.new(redis_url)

      expect(redis).to receive(:del).with('somekey')

      driver.delete('somekey')
    end
  end

  describe '#all' do
    let(:redis_url) { double('redis url') }
    let(:redis) { double('redis') }
    let(:driver) { ::Hitnmiss::RedisDriver.new(redis_url) }
    let(:separator) { Hitnmiss::Repository::KeyGeneration::KEY_COMPONENT_SEPARATOR }
    let(:keyspace) { 'foo' }
    let(:pattern) { "foo#{separator}*" }

    before do
      allow(Redis).to receive(:new).and_return(redis)
    end

    it 'gets keys that match the keyspace' do
      expect(driver).to receive(:get_keys).with(pattern).and_return([])
      driver.all(keyspace)
    end

    context 'when there are matching keys' do
      it 'gets all the values' do
        allow(driver).to receive(:get_keys).with(pattern)
          .and_return(['foo.1', 'foo.2'])
        expect(redis).to receive(:mget).with('foo.1', 'foo.2').and_return([])
        driver.all(keyspace)
      end

      it 'loads each value' do
        allow(driver).to receive(:get_keys).with(pattern)
          .and_return(['foo.1', 'foo.2'])
        foo_value = double('marshalled foo')
        allow(redis).to receive(:mget).with('foo.1', 'foo.2')
          .and_return([foo_value, nil])
        expect(driver).to receive(:deserialize_value).with(foo_value).
          and_return({ value: 'foo' })
        driver.all(keyspace)
      end

      it 'returns the loaded values' do
        allow(driver).to receive(:get_keys).with(pattern)
          .and_return(['foo.1', 'foo.2'])
        foo_value = double('marshalled foo')
        allow(redis).to receive(:mget).with('foo.1', 'foo.2')
          .and_return([foo_value, nil])
        allow(driver).to receive(:deserialize_value).with(foo_value)
          .and_return({ value: 'baz' })
        expect(driver.all(keyspace)).to match_array(['baz'])
      end
    end

    context 'when there are not matching keys' do
      it 'returns an empty collection' do
        keyspace = 'foo'
        allow(driver).to receive(:get_keys).with(pattern).and_return([])
        expect(driver.all(keyspace)).to eq([])
      end
    end
  end

  describe '#clear' do
    let(:redis_url) { double('redis url') }
    let(:redis) { double('redis') }
    let(:driver) { ::Hitnmiss::RedisDriver.new(redis_url) }
    let(:separator) { Hitnmiss::Repository::KeyGeneration::KEY_COMPONENT_SEPARATOR }

    before do
      allow(Redis).to receive(:new).and_return(redis)
    end

    it 'gets keys that match the keyspace' do
      keyspace = 'foo'
      expect(driver).to receive(:get_keys).with("foo#{separator}*")
        .and_return([])
      driver.clear(keyspace)
    end

    context 'when there are matching keys' do
      it 'deletes the matching keys' do
        keyspace = 'foo'
        allow(driver).to receive(:get_keys).with("foo#{separator}*")
          .and_return(['foo.1', 'foo.2'])
        expect(redis).to receive(:del).with('foo.1', 'foo.2')
        driver.clear(keyspace)
      end
    end

    context 'when there are not matching keys' do
      it 'does not delete anything' do
        keyspace = 'foo'
        allow(driver).to receive(:get_keys).with("foo#{separator}*")
          .and_return([])
        expect(redis).not_to receive(:del)
        driver.clear(keyspace)
      end
    end
  end

  describe '#get_keys' do
    let(:redis_url) { double('redis url') }
    let(:redis) { double('redis') }
    let(:driver) { ::Hitnmiss::RedisDriver.new(redis_url) }
    let(:separator) { Hitnmiss::Repository::KeyGeneration::KEY_COMPONENT_SEPARATOR }
    let(:pattern) { "foo#{separator}*" }

    before do
      allow(Redis).to receive(:new).and_return(redis)
    end

    it 'scans for each matching key' do
      expect(redis).to receive(:scan_each).with(match: pattern)
      driver.send(:get_keys, pattern)
    end

    it 'returns all matching keys' do
      allow(redis).to receive(:scan_each).with(match: pattern)
        .and_yield("foo#{separator}1").and_yield("foo#{separator}2")
      expect(driver.send(:get_keys, pattern))
        .to match_array ["foo#{separator}1", "foo#{separator}2"]
    end
  end

  describe '#deserialize_value' do
    let(:redis_url) { double('redis url') }
    let(:redis) { double('redis') }
    let(:driver) { ::Hitnmiss::RedisDriver.new(redis_url) }

    it 'deserializes the value' do
      allow(Redis).to receive(:new).and_return(redis)
      value = double('dumped value')
      expect(Marshal).to receive(:load).with(value)
      driver.send(:deserialize_value, value)
    end
  end

  describe '#serialize_value' do
    let(:redis_url) { double('redis url') }
    let(:redis) { double('redis') }
    let(:driver) { ::Hitnmiss::RedisDriver.new(redis_url) }

    it 'serializes the value' do
      allow(Redis).to receive(:new).and_return(redis)
      value = double('value')
      expect(Marshal).to receive(:dump).with(value)
      driver.send(:serialize_value, value)
    end
  end
end
