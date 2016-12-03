FROM base/archlinux

RUN printf '%s\n' 'Server = http://172.17.0.1:34000/arch/$repo/os/$arch' | \
        tee /etc/pacman.d/mirrorlist
RUN true \
    && pacman --noconfirm --needed -Sy \
    && pacman --noconfirm --needed -S archlinux-keyring \
    && pacman --noconfirm --needed -Su \
    && pacman-db-upgrade \
    && pacman --noconfirm --needed -S \
        gcc \
        git \
        make \
        ruby \
        sudo \
    && groupadd --gid 1000 archache \
    && useradd --create-home --uid 1000 --gid 1000 archache \
    && true

ENV WORKDIR /home/archache
WORKDIR "${WORKDIR}"
COPY [".", "."]

RUN true \
    && chown --recursive archache:archache "${WORKDIR}" \
    && sudo -u archache bash -c ' true \
        && gem install --no-document --bindir _gem_bin --user-install bundler \
        && _gem_bin/bundler install --deployment --local \
        && printf -- '\''---\ncache_dir: /cache\n'\'' | tee config.yaml \
        && true' \
    && pacman --noconfirm -Rncs \
        gcc \
        git \
        make \
        sudo \
    && true

USER archache
CMD ruby _gem_bin/bundler exec ruby app.rb -p 9000 -o 0.0.0.0

# vim: et ts=4 sw=4
