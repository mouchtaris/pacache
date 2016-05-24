[![security](https://hakiri.io/github/mouchtaris/pacache/master.svg)](https://hakiri.io/github/mouchtaris/pacache/master)

# Archlinux Pacman Caching Service


This is not a mirror exactly, rather than a local, efficient, caching
service.

## How it behaves to clients

Archache (pacache) receives requests from pacman clients, who are
trying to HTTP get files from a mirror.

* If this file is found in the cache, then it is served immediately.
* If this file is missing, then a 503 (temporariliy unavailable) is
  returned to the client. The client can try again later (soon).
* If the file could not be retrieved from a real mirror, then a 404 is
  returned to the client and future retries will behave the same.

## How it behaves to mirrors (and what happens behind the scenes)

When a cache miss happens, archache will immediately send 503 to the
client, but it will also start fetching the file from a real mirror.

File-acquisition tasks are queued up in a job queue, as clients make
more and more requests. With the default pacman settings and
downloader, this means that after a failed download (503), the client
will keep making more requests to archache with the rest of the
dependencies.

This way, all dependencies are at once accumulated as jobs, and pacache
will use default parallelisation (#CPU = #threads) to fetch all the
dependencies from mirrors.

If more than one mirrors are configured, they are used in round-robin
fashion.

So, in the end, arcache makes parallel, bound in number, requests, to a
number of mirrors for fetching requested files.

## How it behaves to clients a bit later

Next time a client retries to fetch a file, if it has been fetched they
will get it back with a simple 200 Found. If it is still being
downloaded they will still get a 503. If fetching failed for any reason
(including other 503s from chained caches...), the client will get back
404 - Never retry again.

## How it behaves on the filesystem (or how it behaves as a cache)

Archache stores files directly to a configured directory. When a
requesst is made, it checks if a file entry for that file name exists.
An entry could be:

* a file with that name exactly, which signals a cached file that can
  be served to the client,
* a file with that name + '.failed' appended, which means the file
  failed to be acquired, and the client should be notified (with 404).

One could also spot `"#{filename}.part"` files, which means the file is
being downloaded, but this is never inspected by pacache. It uses the
internal, thread-safe queue, for keeping track of file being fetched.

## How to deal with it

Three things:

One, *config.yaml*

    cache_dir: /somewhere

Two, *mirrors.yaml*

    # NOTICE: no $arch/os/$repo
    - http://mirror.one/
    # NOTICE: no https
    - http://mirror.two/

Three, `rm cache_dir/**.failed`, to clean cache failures and have pacache
retry to fetch these files next time a client requests them.

## Docker image

### Building it

    docker build -t you/archache .

In order to speed up the build, it is recommended you do a `bundler
package --all` beforehand.

Also, if you are running archache somewhere already, you could add it
as a mirror in the beginning of the Dockerfile, as such

    RUN printf '%s\n' 'Service = http://localhost:6666/' | tee
    /etc/pacman.d/mirrorlist

### Running it

    export CACHE_DIR=/where/do/i/want/to/place/my/cache/questionmark
    export CACHE_PORT=12738 # or something else
    export CACHE_MIRRORS='- http://mirror.one\n- http://mirror.two\n'
    mkdir -pv "$CACHE_DIR"
    docker run \
        --name archache \
        --volume "$CACHE_DIR":cache \
        --publish "$CACHE_PORT":9000 \
        --env ARCHACHE_MIRRORS="$CACHE_MIRRORS" \
        --user "$(id -u):$(id -g)" \
        --interactive \
        --tty \
        --detach \
        you/archache

The docker image comes preconfigured, using

    cache_dir: /cache

It is recommended to bind a volume (to the filesystem or pure) for that
directory.

The webserver will start listening at 0.0.0.0:9000. So, expose/forward
that port.

Make sure the mount cache dir is writable by all or by user 1000:1000.

The `ARCHACHE_MIRRORS` env is a `printf(1)` formatted YAML string,
which is evaluated directly using printf.
