
set -ex

git clone https://git.fuwafuwa.moe/premiere/premiere-libtorrent.git --depth=1
git clone https://git.fuwafuwa.moe/premiere/premiere-deluge-plugin.git --depth=1
git clone https://github.com/deluge-torrent/deluge.git
git clone https://github.com/boostorg/boost.git --depth=1 --branch=boost-1.72.0

apt update
apt install build-essential libssl-dev -y

pushd boost
export BOOST_ROOT=$PWD
git submodule update --init --depth=1
./bootstrap.sh
./b2 cxxstd=11 release install --with-python --with-system
pushd tools/build
./bootstrap.sh
./b2 install --prefix=/usr/
ln -s /usr/local/lib/libboost_python27.so /usr/local/lib/libboost_python.so
export PATH=$BOOST_ROOT:$PATH
popd
popd

pushd premiere-libtorrent
git submodule update --init --recursive
b2 toolset=gcc link=shared variant=release target-os=linux address-model=64 crypto=openssl
cp bin/gcc-*/release/address-model-64/crypto-openssl/threading-multi/libtorrent.so* /usr/local/lib
ldconfig
pushd bindings/python/
b2 toolset=gcc link=shared variant=release target-os=linux address-model=64 libtorrent-link=shared
cp bin/gcc*/release/address-model-64/lt-visibility-hidden/python-2.7/libtorrent.so /usr/local/lib/python2.7/site-packages
popd
popd

pushd deluge
git tag -d deluge-2.0.0
git tag deluge-2.0.0
pip install .
popd

deluged
sleep 3
pkill -f deluged

pushd premiere-deluge-plugin
python setup.py bdist_egg
cp dist/*.egg ~/.config/deluge/plugins
popd

