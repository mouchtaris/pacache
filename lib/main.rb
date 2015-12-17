require 'fileutils'
require 'yaml'
require 'net/http'
require 'tilt/haml'
require 'tilt/sass'
require 'uri'
require 'pp'
require 'haml'

require_relative 'pacache'


$logf = File.open 'log', 'w'
$db = nil

def log *stuff
  PP.pp stuff, $logf
  $logf.flush
end

def db
  $db ||= Pacache::DB.new
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

def prepare_serving
  if File.exist?(Pacache::DB::NEW) then
    raise "Forget it. #{Pacache::DB::NEW} exists"
  else
    FileUtils::Verbose.mkdir Pacache::DB::NEW
  end
end

def consolidate
  log "Consolidating database"

  the_db = db.internal_hash!
  newz = Dir['new/*']

  yamlz = newz.to_enum.lazy.map { |nu| File.open(nu, 'r', &YAML.method(:load)) }
  yamlz.each do |entry|
    log "Consolidating: #{entry.to_a.first.first}"
    the_db.merge! entry
  end
  log "Cleaning up databases"
  the_db.reject! { |k, v| /(core|extra|community)\.db(\.sig)?$/.match(k) }

  log "Writing New database"
  File.open(Pacache::DB::DB, 'w') do |fout| YAML.dump(the_db, fout) end
end
