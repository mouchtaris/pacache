class Loggerer

  def initialize(sink)
    @sink = sink
  end

  def begin(module_, method, *rest)
    desc = "[#{module_}:#{method}](#{rest.map(&:to_s).join(', ')}"
    Loggyrer.new(self, desc)
  end

  def sip(str)
    @sink.puts(str)
  end

end

class Loggyrer

  def initialize(loggerer, desc)
    @loggerer = loggerer
    @desc = desc.freeze
  end

  def call(hash)
    @loggerer.sip('%s %s: %s' % [
      Time.now.to_s,
      @desc,
      hash.to_json
    ])
  end

end
