FROM base/archlinux

RUN true \
    && pacman -Su \
    && pacman -S archlinux-keyring \
    && pacman -Sy \
    && pacman-db-upgrade \
    && pacman -S \
        ruby \
        sudo \
    && groupadd --gid 1000 archache \
    && adduser --create-home --uid 1000 --gid 1000 archache \
    && true

WORKDIR /home/arcache
COPY [".", "."]

RUN true \
    && chown --recursive archache:archache "${WORKDIR}" \
    && sudo -u archache bash -c ' true \
        && gem install --no-document --bindir _gem_bin --user-install bundler \
        && _gem_bin/bundler install --deployment --local \
        && printf '\''---\ncache_dir: /archache\n'\'' | tee config.yaml \
        && true' \

USER archache
CMD _gem_bin/bundler exec ruby app.rb -p 9000 -o 0.0.0.0

# vim: et ts=4 sw=4
