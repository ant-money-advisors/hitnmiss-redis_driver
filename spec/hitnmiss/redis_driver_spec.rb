require 'spec_helper'

describe Hitnmiss::RedisDriver do
  let(:driver) { Hitnmiss::RedisDriver.new('redis://localhost/15') }

  before do
    driver.instance_variable_get(:@redis).flushdb
  end

  it 'has a version number' do
    expect(Hitnmiss::RedisDriver::VERSION).not_to be nil
  end

  describe 'create an instance of the Hitnmiss::RedisDriver' do
    it 'creates an instance of Hitnmiss::RedisDriver' do
      expect(driver).to be_a(Hitnmiss::RedisDriver)
    end
  end

  describe 'set a value' do
    context 'when given an expiration' do
      it 'stores the given value with the given key and expiration' do
        entity = Hitnmiss::Entity.new('hoopty', expiration: 30)
        driver.set('foo', entity)
      end
    end

    context 'when NOT given an expiration' do
      it 'stores the given value without an expiration' do
        entity = Hitnmiss::Entity.new('hoopty')
        driver.set('foo', entity)
      end
    end
  end

  describe 'get an unset value' do
    it 'returns Hitnmiss::Driver::Miss' do
      expect(driver.get('unsetjacked')).to be_a(Hitnmiss::Driver::Miss)
    end
  end

  describe 'get a previously set value' do
    it 'returns the obtained value' do
      entity = Hitnmiss::Entity.new('bar', expiration: 30)
      driver.set('foo', entity)
      hit = driver.get('foo')
      expect(hit).to be_a(Hitnmiss::Driver::Hit)
      expect(hit.value).to eq('bar')
      expect(hit.updated_at).not_to be_nil
    end
  end

  describe 'get a previously set value with a fingerprint' do
    it 'returns the obtained value & fingerprint' do
      entity = Hitnmiss::Entity.new('bar', expiration: 30, fingerprint: 'wootprint')
      driver.set('foo', entity)
      hit = driver.get('foo')
      expect(hit).to be_a(Hitnmiss::Driver::Hit)
      expect(hit.value).to eq('bar')
      expect(hit.fingerprint).to eq('wootprint')
    end
  end

  describe 'get a previously set value with a last_modified' do
    it 'returns the obtained value & fingerprint' do
      entity = Hitnmiss::Entity.new('bar', expiration: 30, last_modified: '2016-04-14T11:00:00Z')
      driver.set('foo', entity)
      hit = driver.get('foo')
      expect(hit).to be_a(Hitnmiss::Driver::Hit)
      expect(hit.value).to eq('bar')
      expect(hit.last_modified).to eq('2016-04-14T11:00:00Z')
    end
  end

  describe 'get an expired value' do
    it 'returns a miss' do
      entity = Hitnmiss::Entity.new('doopty', expiration: 1)
      driver.set('hoopty', entity)
      sleep 2
      expect(driver.get('hoopty')).to be_a(Hitnmiss::Driver::Miss)
    end
  end

  describe 'delete a value' do
    it 'deletes cached value' do
      entity = Hitnmiss::Entity.new('bar', expiration: 30)
      driver.set('foo', entity)
      driver.delete('foo')
      expect(driver.get('foo')).to be_a(Hitnmiss::Driver::Miss)
    end

    it 'deletes uncached value without raising an error' do
      driver.delete(SecureRandom.uuid)
    end
  end

  describe 'get values' do
    let(:separator) { Hitnmiss::Repository::KeyGeneration::KEY_COMPONENT_SEPARATOR }

    it 'returns all matching values' do
      entity1 = Hitnmiss::Entity.new(1, expiration: 30)
      entity2 = Hitnmiss::Entity.new({ two: [2] }, expiration: 30)
      entity3 = Hitnmiss::Entity.new(false, expiration: 30)
      entity4 = Hitnmiss::Entity.new('doopty', expiration: 30)
      driver.set("foo#{separator}1", entity1)
      driver.set("foo#{separator}bar:2", entity2)
      driver.set("foo#{separator}bar:baz:3", entity3)
      driver.set('hoopty', entity4)
      expect(driver.all('foo')).to match_array([1, { two: [2] }, false])
    end
  end

  describe 'clear values' do
    let(:separator) { Hitnmiss::Repository::KeyGeneration::KEY_COMPONENT_SEPARATOR }

    it 'clears all matching values' do
      entity1 = Hitnmiss::Entity.new(1, expiration: 30)
      entity2 = Hitnmiss::Entity.new({ two: [2] }, expiration: 30)
      entity3 = Hitnmiss::Entity.new(false, expiration: 30)
      entity4 = Hitnmiss::Entity.new('doopty', expiration: 30)
      driver.set("foo#{separator}1", entity1)
      driver.set("foo#{separator}bar:2", entity2)
      driver.set("foo#{separator}bar:baz:3", entity3)
      driver.set('hoopty', entity4)
      driver.clear('foo')
      expect(driver.all('foo')).to be_empty
      expect(driver.get('hoopty').value).to eq 'doopty'
    end
  end
end
