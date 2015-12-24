def new_main
  Class.new {
    include Main

    def db
      @db ||= Pacache::DB.new
    end

    def logf
      @logf ||= File.open 'log', 'w'
    end
  }.new
end
