#
# Mixed object:
# - logf [File] the log stream
#
module Loggerer

  def log *stuff
    PP.pp stuff, logf
    logf.flush
  end

end
