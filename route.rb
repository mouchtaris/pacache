require_relative 'lib/main'
require 'sinatra'

prepare_serving

get '/os/Linux/distr/archlinux/:repo/os/:arch/*' do |repo, arch, path|
  realurl = Pacache.make_real_url(repo, arch, path)
  log 'request for', repo, arch, path
  entry = serve realurl
  status entry[:status]
  entry[:data]
end

get '*' do |wat|
  @wat = wat
  status 404
  haml :what
end

