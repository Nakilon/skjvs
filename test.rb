require "minitest/autorun"
require_relative "lib/skjvs"
describe SKJVS do

  it "basic test" do
    File.delete SKJVS::OneFile::DEFAULT_FILENAME if File.exist? SKJVS::OneFile::DEFAULT_FILENAME
    store = SKJVS::OneFile.new
    assert_nil store[123]
    store[123] = 123
    assert_equal 123, store[123]
    store[234] = 234
    store[123] = "2\n3"
    assert_equal "2\n3", store[123]
    assert_equal 2, store.instance_variable_get(:@cache).keys.size
  end

  it "fuzz behaviour comparison with Hash (and Sequel, for rake benchmark validity)" do
    store = {}
    require "sequel"
    require "logger"
    db = Sequel.connect "sqlite://sqlite.db"
    db.drop_table :table if db.tables.include? :table
    db.create_table :table do
      String :key, primary_key: true
      String :value
    end
    dbs = 10.times.map{ Sequel.connect("sqlite://sqlite.db")[:table] }
    File.delete SKJVS::OneFile::DEFAULT_FILENAME if File.exist? SKJVS::OneFile::DEFAULT_FILENAME
    stores = 10.times.map{ SKJVS::OneFile.new }

    hit = lambda do
      keys = store.keys
      next if keys.empty?
      key = keys.sample
      fail unless dbs.sample[key: Digest::MD5.hexdigest(key.to_s)][:value]
      fail unless stores.sample[key]
    end
    miss = lambda do
      fail if dbs.sample[key: rand]
      fail if stores.sample[rand]
    end
    append = lambda do
      rand = rand()
      store[rand] = rand
      dbs.sample.insert(key: Digest::MD5.hexdigest(rand.to_s), value: JSON.generate(rand))
      stores.sample[rand] = rand
    end
    edit = lambda do
      keys = store.keys
      next if keys.empty?
      rand = keys.sample
      store[rand] = rand
      fail if dbs.sample.where(key: Digest::MD5.hexdigest(rand.to_s)).update(value: JSON.generate(rand)).zero?
      stores.sample[rand] = rand
    end

    10000.times do
      [hit, miss, append, edit].sample.call
    end
    h = store.map{ |k, v| [Digest::MD5.hexdigest(k.to_s), v] }.to_h
    s = dbs.sample.to_hash :key, :value
    assert_equal h.transform_values{ |_| JSON.generate _ }, s
    x = stores.sample.tap{ |_| _["for sync"] }.instance_variable_get(:@cache)
    assert_equal h, x
  end

end
