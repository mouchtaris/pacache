require_relative '../lib/main'

def new_main
  Class.new {
    include Main

    def db
      @db ||= load_pacache_db
    end

    def logf
      @logf ||= open_log_file
    end

    private

    def load_pacache_db
      log 'Loading database...'
      Pacache::DB.new
    end

    def open_log_file
      log 'Open log file'
      File.open 'log', 'w'
    end

  }.new
end
