require 'sinatra'
require_relative 'ruby/cache'
require_relative 'ruby/mirror'
require_relative 'ruby/loggerer'
require_relative 'ruby/di'
require_relative 'ruby/config'
require 'yaml'
require 'hashie'

di = DI.new

begin
  di.config = Config.load_config
end

begin
  mirrors = Config.load_mirrors
  di.mirror = Mirror.new(di, mirrors)
end

begin
  logf = File.open('logs', 'w')
  sink = -> (msg) { logf.puts(msg); logf.flush }
  di.logger = Loggerer.new(sink)
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

