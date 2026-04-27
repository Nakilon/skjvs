module SKJVS
  class OneFile
    require "json"
    require "digest"
    DEFAULT_FILENAME = "skjvs_store.txt"

    def initialize path = DEFAULT_FILENAME
      @path = path
      @cache = {}
      @pos = 0
    end

    def [] key
      ::File.open @path, "r" do |file|
        file.flock ::File::LOCK_SH

        # TODO: do not parse values until EOF is reached
        file.seek @pos
        while line = file.gets
          next if line.start_with? " "
          @cache[line[0, 32].freeze] = ::JSON.parse line[33..-2]
        end
        @pos = file.pos

      end if ::File.size(@path) > @pos if ::File.exist?(@path)
      @cache[::Digest::MD5.hexdigest key.to_s]
    end

    def []= key, value
      ::File.open @path, "a" do |file|
        file.flock ::File::LOCK_EX
        file.puts "#{::Digest::MD5.hexdigest key.to_s} #{::JSON.generate value}"
        file.flush
      end
    end

  end
end
