module Pacache

extend self
Mirror = 'http://ftp.nluug.nl/os/Linux/distr/archlinux/%{repo}/os/%{arch}/%{path}'

def make_real_url(repo, arch, path)
  URI.parse sprintf(Mirror, repo: repo, arch: arch, path: path)
end



class DB

  DB = 'pacache.db'
  NEW = 'new'

  def initialize
    @db = File.open DB, 'r', &YAML.method(:load)
    @count = 0
  end

  def internal_hash!; @db end

  def size
    YAML.dump(internal_hash!).size
  end

  def key_for(*keys)
    File.join(*keys.map(&:to_s))
  end

  def lookup(*keys)
    @db[key_for(*keys)]
  end

  def update(data, *keys)
    key = key_for(*keys)
    @db[key] = data
    path = File.join(NEW, @count.to_s)
    @count += 1
    if File.exist?(path) then
      raise "UNACCEPTABLE: path exists: #{path}"
    end
    File.open(path, 'w') do |fout|
      YAML.dump({key => data}, fout)
    end
    data
  end

end


end # module Pacache
