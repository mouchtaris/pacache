#
# Mixed object:
# - db [Pacache::DB] the db
#
module Server

  private \
  def prepare_db_files
    %w[ core extra community ].each do |repo|
      url = Pacache.make_real_url(repo, 'x86_64', "#{repo}.db")
      serve(url)
    end
  end

  def prepare_serving
    prepare_db_files
  end

  def remote_get(url)
    req = Net::HTTP::Get.new(url.to_s)
    Net::HTTP.start(url.host, url.port) { |http| http.request(req) }
  end

  def serve(url)
    if data = db.lookup(url) then
      log 'db hit'
      {status: 200, data: data}
    else
      log 'fetching from', url
      res = remote_get(url)
      case res
      when Net::HTTPSuccess
        log 'fetched and serving', url
        db.update(res.body, url)
      else
        log 'fetching failed', url, res
      end
      {status: res.code, data: res.body}
    end
  end

end # module Server
