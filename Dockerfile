FROM jruby:latest

ENV WORKDIR /home/archache
WORKDIR "${WORKDIR}"
COPY [".", "."]
RUN chown --recursive 1000:1000 .
RUN bundler install --deployment
USER 1000:1000
CMD bundler exec ruby app.rb -p 9000 -o 0.0.0.0

# vim: et ts=4 sw=4
