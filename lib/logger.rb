#
# Mixed object:
# - logf [File] the log stream
#
module Logger

  def log *stuff
    PP.pp stuff, logf
    logf.flush
  end

end
