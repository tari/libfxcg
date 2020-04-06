FROM scratch
MAINTAINER Peter Marheine <peter@taricorp.net>

FROM debian:buster-slim AS prereqs
RUN apt-get -qq update
RUN apt-get -y install build-essential libmpfr-dev libmpc-dev libgmp-dev libpng-dev ppl-dev curl git cmake texinfo

FROM prereqs AS binutils
WORKDIR /
RUN curl -L http://ftpmirror.gnu.org/binutils/binutils-2.34.tar.bz2 | tar xj
RUN mkdir build-binutils
WORKDIR /build-binutils
RUN ../binutils-2.34/configure --target=sh3eb-elf --disable-nls \
        --with-sysroot --program-prefix=prizm-
RUN make -j$(nproc)
RUN make install

FROM binutils AS gcc
WORKDIR /
RUN curl -L http://ftpmirror.gnu.org/gcc/gcc-9.3.0/gcc-9.3.0.tar.xz | tar xJ
RUN mkdir build-gcc
WORKDIR /build-gcc
RUN ../gcc-9.3.0/configure --target=sh3eb-elf --program-prefix=prizm- \
        --with-sysroot=/usr/local/fxcg --with-native-system-header-dir=/include \
        --without-headers --enable-languages=c,c++ \
        --disable-tls --disable-nls --disable-threads --disable-shared \
        --disable-libssp --disable-libvtv --disable-libada \
        --with-endian=big --with-multilib-list=
RUN make -j$(nproc) inhibit_libc=true all-gcc
RUN make install-gcc

RUN make -j$(nproc) inhibit_libc=true all-target-libgcc
RUN make install-target-libgcc

FROM gcc AS libfxcg
WORKDIR /
RUN git clone https://github.com/Jonimoose/libfxcg.git
WORKDIR /libfxcg
RUN mkdir -p /usr/local/fxcg/include/sys
RUN mkdir -p /usr/local/fxcg/include/fxcg
RUN install -t /usr/local/fxcg/include include/*.h
RUN install -t /usr/local/fxcg/include/fxcg include/fxcg/*.h
RUN install -t /usr/local/fxcg/include/sys include/sys/*.h

RUN make
RUN mkdir -p /usr/local/fxcg/lib
RUN install -t /usr/local/fxcg/lib lib/libc.a lib/libfxcg.a
RUN install -t /usr/local/fxcg toolchain/prizm.x

RUN touch empty.c
RUN prizm-gcc -c -o empty.o empty.c
RUN for suffix in 1 i begin end n; do \
        rm /usr/local/lib/gcc/sh3eb-elf/9.3.0/crt${suffix}.o && \
        ln empty.o /usr/local/lib/gcc/sh3eb-elf/9.3.0/crt${suffix}.o; \
    done

FROM prereqs AS mkg3a
WORKDIR /
RUN curl https://gitlab.com/taricorp/mkg3a/-/archive/master/mkg3a-master.tar.bz2 | tar xj
WORKDIR /mkg3a-master
RUN cmake .
RUN cmake --target=install --build .

FROM debian:buster-slim
COPY --from=binutils /usr/local/ /usr/local/
COPY --from=gcc /usr/local/ /usr/local/
COPY --from=libfxcg /usr/local/ /usr/local/
COPY --from=mkg3a /usr/local/ /usr/local/

