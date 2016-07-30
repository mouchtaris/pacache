require 'net/http'
require 'concurrent/atomic/atomic_fixnum'

class Mirror

  def initialize(di, mirrors, path_components)
    @di = di
    @mirrors = mirrors.to_a.freeze
    @path_components = path_components.to_a.freeze
    @next = Concurrent::AtomicFixnum.new(0)
  end

  def url_for(mirror, path)
    raise "path#{path.size} vs comp#{@path_components.size}" \
      unless path.size == @path_components.size
    format = format(mirror, @path_components.zip(path).to_h)
    url = URI.parse(format)
    url
  end

  def get(*path)
    loggy = @di.logger.begin(Mirror, :get, *path)

    i = @next.update { |i| (i + 1) % @mirrors.length }
    mirror = @mirrors[i]
    url = url_for(mirror, path)
    loggy.(i: i, url: url)

    response = Net::HTTP.get_response(url)
    loggy.(response: response.inspect)

    if response.is_a? Net::HTTPSuccess
      response.body.tap do |body|
        loggy.(sum: Digest::MD5.hexdigest(body))
      end
    else
      raise 'acquisition error'
    end
  end

end
