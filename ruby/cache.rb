require 'concurrent/map'
require 'concurrent/edge/future'
require 'fileutils'

class Cache

  def initialize(di)
    @di = di
    @in_progress = Concurrent::Map.new
  end
  attr_reader :di

  def in_progress
    @in_progress.size
  end

  def fetch(repo, arch, path)
    CacheAccess.new(self, repo, arch, path).fetch
  end

  def mark_in_progress(path)
    is_present = @in_progress.put_if_absent(path, true)
    locked = !is_present
    locked
  end

  def mark_done(path)
    @in_progress.delete(path)
  end

end

class CacheAccess

  def initialize(cache, repo, arch, path)
    @cache = cache
    @repo = repo
    @arch = arch
    @path = path
  end

  def filepath
    File.join(di.config.cache_dir, @repo, @arch, @path)
  end

  def partial_filepath
    "#{filepath}.part"
  end

  def failure_filepath
    "#{filepath}.failed"
  end

  def fetch
    return_if_files_found || begin_fetch
  end


  private
  include FileUtils::Verbose

  def begin_fetch
    @cache.mark_in_progress(filepath) && (return_if_files_found || begin_http_get)
  end

  def return_if_files_found
    case
    when File.exist?(failure_filepath) then nil
    when File.exist?(filepath) then filepath
    end
  end

  def begin_http_get
    loggy = get_loggy(filepath)

    Concurrent.future(:io) { di.mirror.get(@repo, @arch, @path) }
      .then { |data| complete(loggy, data) }
      .rescue { |data| fail(loggy, data) }
    nil
  end

  def complete(loggy, data)
    loggy.('writing to file')
    FileUtils::Verbose.mkdir_p File.dirname(filepath)
    File.open(partial_filepath, 'w') { |out| out.write(data) }
    File.rename(partial_filepath, filepath)
    finally
  end

  def fail(loggy, data)
    loggy.(error: data)
    File.open(failure_filepath, 'w') { }
    finally
  end

  def finally
    @cache.mark_done(filepath)
  end

  def di
    @cache.di
  end

  def get_loggy(*args)
    di.logger.begin(CacheAccess, caller_locations.last.label, *args)
  end
end
