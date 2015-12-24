module Pacache

require_relative 'pacache/db'
extend self

def mirror
  'http://ftp.nluug.nl/os/Linux/distr/archlinux/%{repo}/os/%{arch}/%{path}'
end

def make_real_url(repo, arch, path)
  URI.parse sprintf(mirror, repo: repo, arch: arch, path: path)
end

end # module Pacache
