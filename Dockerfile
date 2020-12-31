FROM python:2

COPY build.sh /build.sh

RUN bash /build.sh

ENTRYPOINT cp /premiere-deluge-plugin/dist/*.egg ~/.config/deluge/plugins/ && deluged && deluge-web --fork
