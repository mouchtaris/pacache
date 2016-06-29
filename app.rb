require 'sinatra'
require 'tilt/haml'
require 'yaml'
require 'hashie'
require 'pry'
require_relative 'ruby/cache'
require_relative 'ruby/mirror'
require_relative 'ruby/loggerer'
require_relative 'ruby/di'
require_relative 'ruby/config'

di = DI.new

begin
  di.config = Config.load_config
end

begin
  mirrors = Config.load_mirrors
    .map { |m| "#{m}/%{repo}/os/%{arch}/%{path}" }.to_a.freeze
  di.mirror = Mirror.new(di, mirrors, %i(repo arch path))
end

begin
  ubuntu_mirrors = Config.load_ubuntu_mirrors
    .map { |m| "#{m}/dists/%{dist}/%{path}" }.to_a.freeze
  di.ubuntu_mirror = Mirror.new(di, ubuntu_mirrors, %i(dist path))
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

get '/arch/:repo/os/:arch/*' do |repo, arch, path|
  result = di.cache.fetch(repo, arch, path)
  case result
  when String then send_file result
  when :fail then status 404
  else status 503
  end
end

get '/ubuntu/*' do
  status 505
end

get '*' do |wat|
  @wat = wat
  status 404
  haml :what
end

