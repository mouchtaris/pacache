require 'concurrent/map'
require 'concurrent/edge/future'
require 'fileutils'

class Cache

  HUMAN_INDEX_DIR = 'human_index'

  def initialize(di)
    @di = di
    @in_progress = Concurrent::Map.new
  end
  attr_reader :di

  def in_progress
    @in_progress.size
  end

  def fetch(repo, arch, path)
    fetch_mirror(di.mirror, 'arch', [repo, arch, path])
  end

  def fetch_ubuntu(dist, path)
    fetch_mirror(di.ubuntu_mirror, 'ubuntu', [dist, path])
  end

  def fetch_mirror(mirror, prefix, path)
    CacheAccess.new(self, mirror, prefix, path).fetch
  end

  def mark_in_progress(path)
    is_present = @in_progress.put_if_absent(path, true)
    locked = !is_present
    locked
  end

  def mark_done(path)
    @in_progress.delete(path)
  end

  def mark_done_hook(access_object)
    mark_done(access_object.filepath)
    add_human_index_entry(access_object)
  end

  def add_human_index_entry(access)
    entry_path = Pathname.new(di.config.cache_dir) + HUMAN_INDEX_DIR + access.filepath
    FileUtils::Verbose.mkdir_p entry_path.dirname
    entry_path
      .open('w') do |fout|
        fout.puts '---'
        fout.puts "- #{access.prefix}"
        access.path.each do |path_element|
          fout.puts "- #{path_element}"
        end
      end
  end
end

class CacheAccess

  def initialize(cache, mirror, prefix, path)
    @cache = cache
    @mirror = mirror
    @prefix = prefix
    @path = path
  end
  attr_reader :path, :prefix

  def filepath
    specific_path = File.join(*@path)
    fs_friendly_path = Digest::SHA512.hexdigest(specific_path)
    File.join(di.config.cache_dir, @prefix, fs_friendly_path)
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
    @cache.mark_in_progress(filepath) &&
      (return_if_files_found || begin_http_get)
  end

  def return_if_files_found
    case
    when File.exist?(failure_filepath) then :fail
    when File.exist?(filepath) then filepath
    end
  end

  def begin_http_get
    loggy = get_loggy(filepath)

    Concurrent
      .future(:io) { @mirror.get(*@path) }
      .then { |data| complete(loggy, data) }
      .rescue { |data| fail(loggy, data) }
    nil
  end

  def complete(loggy, data)
    FileUtils::Verbose.mkdir_p File.dirname(filepath)
    File.open(partial_filepath, 'w') { |out| out.write(data) }
    File.rename(partial_filepath, filepath)
    finally(loggy)
  end

  def fail(loggy, data)
    loggy.(error: data)
    File.open(failure_filepath, 'w') { }
    finally(loggy)
  end

  #
  # @return PATH! important!
  def finally(loggy)
    loggy.(in_progress: @cache.in_progress)
    @cache.mark_done_hook(self)
  end

  def di
    @cache.di
  end

  def get_loggy(*args)
    method = caller_locations
      .map(&:label)
      .find { |label| /\s/.match(label).nil? }
    di.logger.begin(CacheAccess, method, *args)
  end
end
