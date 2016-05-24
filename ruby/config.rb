module Config

  CONFIG_PATH = 'config.yaml'
  MIRRORS_PATH = 'mirrors.yaml'

  class << self

    def loading_config_failed(e)
      puts %q{
        |---
        |#config.yaml
        |cache_dir: cache2
      }.gsub(/^\s+(\||$)/, '')
      raise RuntimeError, e
    end

    def load_config
      Hashie::Mash.new(YAML.load(File.read(CONFIG_PATH)))
    rescue Errno::ENOENT => e
      loading_config_failed
    end

    def loading_mirrors_failed
      puts %q{
        |---
        |#mirrors.yaml
        |- http://ftp.nluug.nl/os/Linux/distr/archlinux
        |- https://mirror.f4st.host/archlinux
        |- http://mirror.f4st.host/archlinux
        |- https://mirror.neuf.no/archlinux
        |- http://mirror.bytemark.co.uk/archlinux
        |- http://foss.aueb.gr/mirrors/linux/archlinux
      }.gsub(/^\s+(\||$)/, '')
      raise RuntimeError, 'loading mirrors failed'
    end

    def load_mirrors
      if File.exist?(MIRRORS_PATH)
        YAML.load(File.read('mirrors.yaml'))
      elsif env_val = ENV['ARCHACHE_MIRRORS']
        sprintf(env_val)
      else
        loading_mirrors_failed
      end
    end

  end

end
