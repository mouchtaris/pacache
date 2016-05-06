class Loggerer

  def initialize(sink)
    @sink = sink
  end

  def begin(module_, method, *rest)
    desc = "[#{module_}:#{method}(#{rest.map(&:to_s).join(', ')})]"
    loggy = Loggyrer.new(self, desc)
    if block_given?
      yield loggy
    else
      loggy
    end
  end

  def sip(str)
    @sink.call(str)
  end

end

class Loggyrer

  def initialize(loggerer, desc)
    @loggerer = loggerer
    @desc = desc.freeze
  end

  def call(something)
    message =
      case something
      when String then something
      else something.inspect
      end
    @loggerer.sip('%s %s: %s' % [Time.now.to_s, @desc, message])
  end

end
