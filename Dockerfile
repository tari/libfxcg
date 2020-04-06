FROM ubuntu:14.04
MAINTAINER Peter Marheine <peter@taricorp.net>
RUN apt-get -qq update
RUN apt-get -y install build-essential libmpfr-dev libmpc-dev libgmp-dev libpng-dev ppl-dev curl git cmake && \
    apt-get clean

# binutils
RUN curl ftp://ftp.gnu.org/gnu/binutils/binutils-2.24.tar.bz2 | tar xj && \
    mkdir build-binutils && \
    cd build-binutils && \
    ../binutils-2.24/configure --target=sh3eb-elf --disable-nls \
        --with-sysroot --program-prefix=prizm- && \
    make -j && \
    make install && \
    cd .. && \
    rm -rf binutils-2.24 build-binutils

# GCC, target libgcc
RUN curl ftp://ftp.gnu.org/gnu/gcc/gcc-4.9.2/gcc-4.9.2.tar.bz2 | tar xj && \
    mkdir build-gcc && \
    cd build-gcc && \
    ../gcc-4.9.2/configure --target=sh3eb-elf --program-prefix=prizm- \
        --with-sysroot=/usr/local/fxcg --with-native-system-header-dir=/include \
        --without-headers --enable-languages=c,c++ \
        --disable-tls --disable-nls --disable-threads --disable-shared \
        --disable-libssp --disable-libvtv --disable-libada \
        --with-endian=big --with-multilib-list= && \
    make -j4 inhibit_libc=true all-gcc && \
    make install-gcc && \
    \
    make -j4 inhibit_libc=true all-target-libgcc && \
    make install-target-libgcc && \
    cd .. && \
    rm -rf build-gcc gcc-4.9.2

# libfxcg, install target headers & libs
RUN git clone https://github.com/Jonimoose/libfxcg.git && \
    cd libfxcg && \
    mkdir -p /usr/local/fxcg/include/sys && \
    mkdir -p /usr/local/fxcg/include/fxcg && \
    install -t /usr/local/fxcg/include include/*.h && \
    install -t /usr/local/fxcg/include/fxcg include/fxcg/*.h && \
    install -t /usr/local/fxcg/include/sys include/sys/*.h && \
    \
    make && \
    mkdir -p /usr/local/fxcg/lib && \
    install -t /usr/local/fxcg/lib lib/libc.a lib/libfxcg.a && \
    install -t /usr/local/fxcg toolchain/prizm.x && \
    \
    touch empty.c && \
    prizm-gcc -c -o empty.o empty.c && \
    for suffix in 1 i begin end n; do \
        rm /usr/local/lib/gcc/sh3eb-elf/4.9.2/crt${suffix}.o && \
        ln empty.o /usr/local/lib/gcc/sh3eb-elf/4.9.2/crt${suffix}.o; \
    done && \
    cd .. && \
    rm -rf libfxcg

# mkg3a
RUN curl https://gitlab.com/taricorp/mkg3a/-/archive/master/mkg3a-master.tar.bz2 | tar xj && \
    cd mkg3a-master && \
    cmake . && make && make install && \
    cd .. && \
    rm -rf mkg3a-master

