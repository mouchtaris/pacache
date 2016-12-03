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
  di.config = AppConfig.load_config
end

begin
  mirrors = AppConfig.load_mirrors
    .map { |m| "#{m}/%{repo}/os/%{arch}/%{path}" }.to_a.freeze
  di.mirror = Mirror.new(di, mirrors, %i(repo arch path))
end

begin
  ubuntu_mirrors = AppConfig.load_ubuntu_mirrors
    .map { |m| "#{m}/%{wat}/%{path}" }.to_a.freeze
  di.ubuntu_mirror = Mirror.new(di, ubuntu_mirrors, %i(wat path))
end

begin
  npm_mirrors = AppConfig.load_npm_mirrors
    .map { |m| "#{m}/%{wat}/%{path}" }.to_a.freeze
  di.npm_mirror = Mirror.new(di, npm_mirrors, %i{path})
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

helpers do
  def serve(cache_result)
    case cache_result
    when String then send_file cache_result
    when :fail then status 404
    else status 503
    end
  end
end

get '/arch/:repo/os/:arch/*' do |repo, arch, path|
  serve di.cache.fetch(repo, arch, path)
end

get '/ubuntu/:wat/*' do |wat, path|
  serve di.cache.fetch_ubuntu(wat, path)
end

get '/npm/*' do |path|
  serve di.cache.fetch_npm(path)
end

def wat(method)
  send method, '*' do |wat|
    @method = method
    @wat = wat
    status 404
    haml :what
  end
end

%i{ get post options head delete put }.each &method(:wat)
