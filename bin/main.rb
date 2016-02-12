require_relative '../lib/main'

def new_main
  Class.new {
    include Main

    def db
      @db ||= load_pacache_db
    end

    def logf
      unless @logf
        @logf = File.open 'log', 'w'
        log 'Open log file'
      end
      @logf
    end

    private

    def load_pacache_db
      log 'Loading database...'
      Pacache::DB.new
    end

  }.new
end
