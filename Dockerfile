FROM python:2
RUN apt update -y
RUN apt install build-essential libssl-dev -y

WORKDIR /
RUN git clone https://git.fuwafuwa.moe/premiere/premiere-libtorrent.git --depth=1
RUN git clone https://git.fuwafuwa.moe/premiere/premiere-deluge-plugin.git --depth=1
RUN git clone https://github.com/deluge-torrent/deluge.git
RUN git clone https://github.com/boostorg/boost.git --depth=1 --branch=boost-1.72.0

WORKDIR /boost
ENV BOOST_ROOT="/boost"
RUN git submodule update --init --depth=1
RUN ./bootstrap.sh
RUN ./b2 cxxstd=11 release install --with-python --with-system

WORKDIR /boost/tools/build
RUN ./bootstrap.sh
RUN ./b2 install --prefix=/usr/
RUN ln -s /usr/local/lib/libboost_python27.so /usr/local/lib/libboost_python.so
ENV PATH="${BOOST_ROOT}:${PATH}"

WORKDIR /premiere-libtorrent
RUN git submodule update --init --recursive
RUN b2 toolset=gcc link=shared variant=release target-os=linux address-model=64 crypto=openssl
RUN cp bin/gcc-*/release/address-model-64/crypto-openssl/threading-multi/libtorrent.so* /usr/local/lib
RUN ldconfig
WORKDIR /premiere-libtorrent/bindings/python
RUN b2 toolset=gcc link=shared variant=release target-os=linux address-model=64 libtorrent-link=shared
RUN cp bin/gcc*/release/address-model-64/lt-visibility-hidden/python-2.7/libtorrent.so /usr/local/lib/python2.7/site-packages

WORKDIR /deluge
RUN pip install .

RUN mkdir -p /config
RUN \
  deluged -c /config && \
  sleep 10 && \
  deluge-console -c /config "config -s allow_remote true" && \
  deluge-console -c /config "config -s download_location /downloads" && \
  deluge-console -c /config "config -s daemon_port 58846" && \
  deluge-console -c /config "config -s random_port false" && \
  deluge-console -c /config "config -s listen_ports (50100,50100)" && \
  deluge-console -c /config "halt" && \
  rm -rf /config/ssl/*

WORKDIR /premiere-deluge-plugin
RUN python setup.py bdist_egg
RUN cp /premiere-deluge-plugin/dist/*.egg /config/plugins/

VOLUME /config

ENTRYPOINT deluged -c /config && \
  deluge-web -c /config --fork && \
  /bin/bash
