task :default do
  sh "rake -T"
end

task :benchmark do
  Thread.abort_on_exception = true
  require_relative "lib/skjvs"
  require "securerandom"
  require_relative "lib/gnuplot"
  [
    [ 128,  1280,  64,  8,  2],
    [ 192,  1920,  96, 12,  3],
    [ 256,  2560, 128, 16,  4],
    [ 384,  3840, 192, 24,  6],
    [ 512,  5120, 256, 32,  8],
    [1024, 10240, 512, 64, 16],
  ].map.with_index do |(key_size, value_size, entries_count, cycles, threads_count), i|

    STDERR.puts "data preparing start"
    data = entries_count.times.map{ [SecureRandom.alphanumeric(key_size), SecureRandom.alphanumeric(value_size)] }
    keys_for_hit = data.map(&:first)
    keys_for_miss = cycles.times.map{ SecureRandom.alphanumeric 10 }
    STDERR.puts "data preparing end"

    # TODO: maybe somehow ensure keys_for_hit hits

    results = []

    File.delete SKJVS::OneFile::DEFAULT_FILENAME if File.exist? SKJVS::OneFile::DEFAULT_FILENAME
    time = threads_count.times.map do
      Thread.new do
        store = SKJVS::OneFile.new
        cycles.times do
          store[keys_for_hit.sample]
          store[keys_for_miss.sample]
          data.sample.tap{ |k, v| store[k] = v }
        end
      end
    end.then do |threads|
      time = Time.now
      threads.each &:join
      Time.now - time
    end
    STDERR.puts [i, "SKJVS", time].inspect
    results.push [threads_count, 1 / time]

    require "sequel"
    File.delete "sqlite.db" if File.exist? "sqlite.db"
    db = Sequel.connect "sqlite://sqlite.db"
    db.create_table :table do
      String :key, primary_key: true
      String :value
    end
    time = threads_count.times.map do
      Thread.new do
        table = Sequel.connect("sqlite://sqlite.db")[:table]
        cycles.times do
          table[key: Digest::MD5.hexdigest(keys_for_hit.sample)]
          fail if table[key: Digest::MD5.hexdigest(rand.to_s)]
          data.sample.tap do |k, v|
            key = Digest::MD5.hexdigest k.to_s
            table.insert_conflict(:replace).insert(key: key, value: JSON.generate(rand))
          end
        end
      end
    end.then do |threads|
      time = Time.now
      threads.each &:join
      Time.now - time
    end
    STDERR.puts [i, "Sequel", time].inspect
    results.push [threads_count, 1 / time]

    require "pstore"
    File.delete "temp.pstore" if File.exist? "temp.pstore"
    time = threads_count.times.map do
      Thread.new do
        store = PStore.new "temp.pstore"
        cycles.times do
          store.transaction(true){ |tr| tr[keys_for_hit.sample] }
          store.transaction(true){ |tr| tr[keys_for_miss.sample] }
          store.transaction{ |tr| data.sample.tap{ |k, v| tr[k] = v } }
        end
      end
    end.then do |threads|
      time = Time.now
      threads.each &:join
      Time.now - time
    end
    STDERR.puts [i, "PStore", time].inspect
    results.push [threads_count, 1 / time]

    require "yaml/store"
    File.delete "temp.yaml" if File.exist? "temp.yaml"
    mutex = Mutex.new
    time = threads_count.times.map do
      Thread.new do
        store = YAML::Store.new "temp.yaml"
        cycles.times do
          mutex.synchronize{ store.transaction(true){ |tr| tr[keys_for_hit.sample] } }
          mutex.synchronize{ store.transaction(true){ |tr| tr[keys_for_miss.sample] } }
          mutex.synchronize{ store.transaction{ |tr| data.sample.tap{ |k, v| tr[k] = v } } }
        end
      end
    end.then do |threads|
      time = Time.now
      threads.each &:join
      Time.now - time
    end
    STDERR.puts [i, "YAML::Store", time].inspect
    results.push [threads_count, 1 / time]

  end.tap{ |results| gnuplot p results.transpose }
end
