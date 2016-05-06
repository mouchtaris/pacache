require 'sinatra'
require_relative 'ruby/cache'
require_relative 'ruby/mirror'
require_relative 'ruby/loggerer'
require_relative 'ruby/di'
require 'yaml'

di = DI.new

begin
  di.logger = Loggerer.new(File.open('logs', 'w'))
end

begin
  mirrors = YAML.parse('mirrors.yaml')
  di.mirror = Mirror.new(di, mirrors)
end

begin
  di.cache = Cache.new(di)
end

get '/:repo/os/:arch/*' do |repo, arch, path|
  filepath = di.cache.fetch(repo, arch, path)
  if filepath
    status 200
    file filepath
  else
    status 503
  end
end

get '*' do |wat|
  @wat = wat
  status 404
  haml :what
end

