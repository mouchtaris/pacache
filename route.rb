require_relative 'lib/main'
require 'sinatra'

main = Class.new {
  include Main

  def db
    @db ||= Pacache::DB.new
  end

  def logf
    @logf ||= File.open 'log', 'w'
  end

}.new # class main

main.prepare_serving

get '/os/Linux/distr/archlinux/:repo/os/:arch/*' do |repo, arch, path|
  realurl = Pacache.make_real_url(repo, arch, path)
  main.log 'request for', repo, arch, path
  entry = main.serve realurl
  status entry[:status]
  entry[:data]
end

get '*' do |wat|
  @wat = wat
  status 404
  haml :what
end

