#
# Mixed object:
# - db [Pacache::DB] the db
#
module Server

  def prepare_serving
    if File.exist?(Pacache::DB::NEW) then
      raise "Forget it. #{Pacache::DB::NEW} exists"
    else
      FileUtils::Verbose.mkdir Pacache::DB::NEW
    end
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

end # module Server