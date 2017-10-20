FROM jruby:latest

ENV WORKDIR /home/archache
WORKDIR "${WORKDIR}"
RUN useradd leon -u 1000 --create-home

ADD [ "Gemfile", "Gemfile.lock", "./" ]
RUN bundler install --deployment

COPY [".", "."]
RUN chown --recursive leon:leon .

USER leon:leon
CMD bundler exec ruby app.rb -p 9000 -o 0.0.0.0

# vim: et ts=4 sw=4
