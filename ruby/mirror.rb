require 'net/http'
require 'concurrent/atomic/atomic_fixnum'

class Mirror

  def initialize(di, mirrors)
    @di = di
    @mirrors = mirrors.map { |m| "#{m}/%{repo}/os/%{arch}/%{path}" }.to_a.freeze
    @next = Concurrent::AtomicFixnum.new(0)
  end

  def get(repo, arch, path)
    loggy = @di.logger.begin(Mirror, :get, repo, arch, path)

    i = @next.update { |i| (i + 1) % @mirrors.length }
    mirror = @mirrors[i]
    url = URI.parse(mirror % {repo: repo, arch: arch, path: path})
    loggy.(i: i, url: url)

    response = Net::HTTP.get_response(url)
    loggy.(response: response.inspect)

    if response.is_a? Net::HTTPSuccess
      response.body
    else
      raise 'acquisition error'
    end
  end

end
