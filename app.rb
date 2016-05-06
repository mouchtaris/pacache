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
end

begin
  logf = File.open('logs', 'w')
  sink = -> (msg) { logf.puts(msg); logf.flush }
  di.logger = Loggerer.new(sink)
end

begin
  mirrors = YAML.load(File.read('mirrors.yaml'))
  di.mirror = Mirror.new(di, mirrors)
end

begin
  di.cache = Cache.new(di)
end

loggy = di.logger.begin(self.class, '<main>')
loggy.(msg: 'HELLO!')

get '/:repo/os/:arch/*' do |repo, arch, path|
  filepath = di.cache.fetch(repo, arch, path)
  if filepath
    send_file filepath
  else
    status 503
  end
end

get '*' do |wat|
  @wat = wat
  status 404
  haml :what
end

