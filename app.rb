require 'sinatra'
require_relative 'ruby/cache'
require_relative 'ruby/mirror'
require_relative 'ruby/loggerer'
require_relative 'ruby/di'
require 'yaml'
require 'hashie'

di = DI.new

begin
  di.config = Hashie::Mash.new(YAML.load(File.read('config.yaml')))
rescue Errno::ENOENT
  puts %q{
    |---
    |#config.yaml
    |cache_dir: cache2
  }.gsub(/^\s+(\||$)/, '')
  exit 1
end

begin
  logf = File.open('logs', 'w')
  sink = -> (msg) { logf.puts(msg); logf.flush }
  di.logger = Loggerer.new(sink)
end

begin
  mirrors = YAML.load(File.read('mirrors.yaml'))
  di.mirror = Mirror.new(di, mirrors)
rescue Errno::ENOENT
  puts %q{
    |---
    |#mirrors.yaml
    |- http://ftp.nluug.nl/os/Linux/distr/archlinux
    |- https://mirror.f4st.host/archlinux
    |- http://mirror.f4st.host/archlinux
    |- https://mirror.neuf.no/archlinux
    |- http://mirror.bytemark.co.uk/archlinux
    |- http://foss.aueb.gr/mirrors/linux/archlinux
  }.gsub(/^\s+(\||$)/, '')
  exit 1
end

begin
  di.cache = Cache.new(di)
end

loggy = di.logger.begin(self.class, '<main>')
loggy.(msg: 'HELLO!')

get '/:repo/os/:arch/*' do |repo, arch, path|
  result = di.cache.fetch(repo, arch, path)
  case result
  when String then send_file result
  when :fail then status 404
  else status 503
  end
end

get '*' do |wat|
  @wat = wat
  status 404
  haml :what
end

