#!/bin/bash
# Build `apkeep` for release from a fresh Debian 10 x64 install

ssh -o 'StrictHostKeyChecking no' apkeep-compiler << 'EOF'
sudo dpkg --add-architecture armhf
sudo dpkg --add-architecture i386
sudo dpkg --add-architecture arm64
sudo apt-get -y update
sudo apt-get -y dist-upgrade
sudo apt-get -y install git build-essential libssl-dev pkg-config unzip gcc-multilib
sudo apt-get -y install libc6-armhf-cross libc6-dev-armhf-cross gcc-arm-linux-gnueabihf libssl-dev:armhf
sudo apt-get -y install libc6-i386-cross libc6-dev-i386-cross gcc-i686-linux-gnu libssl-dev:i386
sudo apt-get -y install libc6-arm64-cross libc6-dev-arm64-cross gcc-aarch64-linux-gnu libssl-dev:arm64
sudo apt-get -y install clang-11 llvm-11 lld-11
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/get_rust.sh
bash /tmp/get_rust.sh -y
source ~/.cargo/env
rustup target install armv7-unknown-linux-gnueabihf i686-unknown-linux-gnu aarch64-unknown-linux-gnu aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android x86_64-pc-windows-msvc

git clone https://www.github.com/EFForg/apkeep.git
cd apkeep
export PKG_CONFIG_ALLOW_CROSS="true"
cargo build --release
export PKG_CONFIG_PATH="/usr/lib/arm-linux-gnueabihf/pkgconfig"
cargo build --release --target=armv7-unknown-linux-gnueabihf
export PKG_CONFIG_PATH="/usr/lib/i686-linux-gnu-gcc/pkgconfig"
cargo build --release --target=i686-unknown-linux-gnu
export PKG_CONFIG_PATH="/usr/lib/aarch-linux-gnu-gcc/pkgconfig"
cargo build --release --target=aarch64-unknown-linux-gnu

cd ~
wget https://www.openssl.org/source/openssl-1.1.1k.tar.gz
tar -zxvf openssl-1.1.1k.tar.gz
cd openssl-1.1.1k
export OPENSSL_DIR=$PWD
export OPENSSL_LIB_DIR=$PWD

cd ~
wget https://dl.google.com/android/repository/android-ndk-r21e-linux-x86_64.zip
# later versions are available, but have to use an earlier version for compatability with openssl-1.1.1k
unzip android-ndk-r21e-linux-x86_64.zip
cd android-ndk-r21e
export ANDROID_NDK_HOME="$PWD"
export PATH="$PATH:$PWD/toolchains/llvm/prebuilt/linux-x86_64/bin"

cd $OPENSSL_DIR
./Configure android-arm64 -D__ANDROID_API__=21
make
cd ../apkeep
cargo build --release --target=aarch64-linux-android

cd $OPENSSL_DIR
make clean
./Configure android-arm -D__ANDROID_API__=21
make
cd ../apkeep
cargo build --release --target=armv7-linux-androideabi

cd $OPENSSL_DIR
make clean
./Configure android-x86 -D__ANDROID_API__=21
make
cd ../apkeep
cargo build --release --target=i686-linux-android

cd $OPENSSL_DIR
make clean
./Configure android-x86_64 -D__ANDROID_API__=21
make
cd ../apkeep
cargo build --release --target=x86_64-linux-android

sudo ln -s clang-11 /usr/bin/clang && sudo ln -s clang /usr/bin/clang++ && sudo ln -s lld-11 /usr/bin/ld.lld
sudo ln -s clang-11 /usr/bin/clang-cl && sudo ln -s llvm-ar-11 /usr/bin/llvm-lib && sudo ln -s lld-link-11 /usr/bin/lld-link && sudo ln -s lld-link /usr/bin/link.exe

cd ~
wget https://github.com/EFForg/apkeep-files/raw/main/openssl-1.1.1m-static-x86_64-pc-windows-msvc.tar.gz
tar -zxvf openssl-1.1.1m-static-x86_64-pc-windows-msvc.tar.gz
cd openssl-1.1.1m
export OPENSSL_DIR=$PWD
export OPENSSL_LIB_DIR=$PWD

XWIN_VERSION="0.1.5"
XWIN_PREFIX="xwin-$XWIN_VERSION-x86_64-unknown-linux-musl"
curl --fail -L https://github.com/Jake-Shadle/xwin/releases/download/$XWIN_VERSION/$XWIN_PREFIX.tar.gz | tar -xzv -C ~/.cargo/bin --strip-components=1 $XWIN_PREFIX/xwin
cd ~ && mkdir xwin
xwin --accept-license 1 splat --output xwin

export CC_x86_64_pc_windows_msvc="clang-cl"
export CXX_x86_64_pc_windows_msvc="clang-cl"
export AR_x86_64_pc_windows_msvc="llvm-lib"
export CL_FLAGS="-Wno-unused-command-line-argument -fuse-ld=lld-link /imsvc$HOME/xwin/crt/include /imsvc$HOME/xwin/sdk/include/ucrt /imsvc$HOME/xwin/sdk/include/um /imsvc$HOME/xwin/sdk/include/shared"
export RUSTFLAGS="-Lnative=$HOME/xwin/crt/lib/x86_64 -Lnative=$HOME/xwin/sdk/lib/um/x86_64 -Lnative=$HOME/xwin/sdk/lib/ucrt/x86_64"
export CFLAGS_x86_64_pc_windows_msvc="$CL_FLAGS"
export CXXFLAGS_x86_64_pc_windows_msvc="$CL_FLAGS"
export OPENSSL_STATIC=1

cd ../apkeep
cargo build --release --target x86_64-pc-windows-msvc
EOF

scp apkeep-compiler:~/apkeep/target/release/apkeep ./apkeep-x86_64-unknown-linux-gnu
scp apkeep-compiler:~/apkeep/target/armv7-unknown-linux-gnueabihf/release/apkeep ./apkeep-armv7-unknown-linux-gnueabihf
scp apkeep-compiler:~/apkeep/target/i686-unknown-linux-gnu/release/apkeep ./apkeep-i686-unknown-linux-gnu
scp apkeep-compiler:~/apkeep/target/aarch64-unknown-linux-gnu/release/apkeep ./apkeep-aarch64-unknown-linux-gnu
scp apkeep-compiler:~/apkeep/target/aarch64-linux-android/release/apkeep ./apkeep-aarch64-linux-android
scp apkeep-compiler:~/apkeep/target/armv7-linux-androideabi/release/apkeep ./apkeep-armv7-linux-androideabi
scp apkeep-compiler:~/apkeep/target/i686-linux-android/release/apkeep ./apkeep-i686-linux-android
scp apkeep-compiler:~/apkeep/target/x86_64-linux-android/release/apkeep ./apkeep-x86_64-linux-android
scp apkeep-compiler:~/apkeep/target/x86_64-pc-windows-msvc/release/apkeep.exe ./apkeep-x86_64-pc-windows-msvc.exe
