require 'fileutils'
require 'yaml'
require 'net/http'
require 'tilt/haml'
require 'tilt/sass'
require 'uri'
require 'sinatra'
require 'pp'
require 'haml'

Mirror = 'http://ftp.nluug.nl/os/Linux/distr/archlinux/%{repo}/os/%{arch}/%{path}'

$logf = File.open 'log', 'w'
$db = nil

def log *stuff
  PP.pp stuff, $logf
  $logf.flush
end

class DB

  DB = 'pacache.db'
  NEW = 'new'

  def initialize
    @db = File.open DB, 'r', &YAML.method(:load)
    @count = 0
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

if File.exist?(DB::NEW) then
  raise "Forget it. #{DB::NEW} exists"
else
  FileUtils::Verbose.mkdir DB::NEW
end

def db
  $db ||= DB.new
end

def remote_get(url)
  req = Net::HTTP::Get.new(url.to_s)
  Net::HTTP.start(url.host, url.port) { |http| http.request(req) }
end

def serve(url)
  if entry = db.lookup(url) then
    log 'db hit'
    entry
  else
    log 'fetching from', url
    res = remote_get(url)
    db.update({status: res.code.to_i, data: res.body}, url)
  end
end

get '/os/Linux/distr/archlinux/:repo/os/:arch/*' do |repo, arch, path|
  realurl = URI.parse sprintf(Mirror, repo: repo, arch: arch, path: path)
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

