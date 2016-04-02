require 'digest/sha2'
require 'pathname'
require 'fileutils'

module Pacache
class DB

  DB = Pathname.new('pacache.db')

  def initialize
    FileUtils::Verbose.mkdir_p DB.to_s
  end

  def internal_hash!
    raise 'no'
  end

  def key_for(*keys)
    File.join(*keys.map(&:to_s))
  end

  def lookup(*keys)
    path = path_for(*keys)
    if path.exist?
      path.read
    end
  end

  def path_for(*keys)
    key = key_for(*keys)
    DB + Digest::SHA512.hexdigest(key)
  end

  def update(data, *keys)
    path_for(*keys).open('wb') do |fout|
      fout.write(data)
    end

    data
  end

end # class DB
end # module Pacache
