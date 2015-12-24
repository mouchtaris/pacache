#
# Mixed object:
# - db [Pacache::DB] the db
#
module Consolidator

  def consolidate
    log "Consolidating database"

    the_db = db.internal_hash!
    newz = Dir['new/*']

    yamlz = newz.to_enum.lazy.map { |nu| File.open(nu, 'r', &YAML.method(:load)) }
    yamlz.each do |entry|
      log "Consolidating: #{entry.to_a.first.first}"
      the_db.merge! entry
    end
    log "Cleaning up databases"
    the_db.reject! { |k, v| /(core|extra|community)\.db(\.sig)?$/.match(k) }

    log "Pry injection for mods"
    pry binding

    log "Writing New database"
    File.open(Pacache::DB::DB, 'w') do |fout| YAML.dump(the_db, fout) end
  end

end # module Consolidator
