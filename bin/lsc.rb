require_relative 'main'

new_main.each_new_with_source.
  map { |y, s|
    sid = /new\/(\d+)$/.match(s)[1]
    key = y.keys.first
    rx = /.*\/([.\w\d-]+)$/
    md = rx.match(key)
    name = md ? md[1] : key
    [ sid, name ]
  }.
  map { |k, n|
    ns = n.split('-')
    [ k, ns[0], ns[1] ]
  }.
  sort_by { |k,| k }.
  each { |k, n, v| printf '%02d: %10s %s%s', k, v, n, "\n" }
