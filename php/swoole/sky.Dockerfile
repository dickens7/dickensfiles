ARG SWOOLE_VERSION=4.6.2

FROM dickens7/swoole:${SWOOLE_VERSION}


##
# ---------- env settings ----------
##
ENV GRPC_RELEASE_TAG v1.31.x
ENV PROTOBUF_RELEASE_TAG 3.13.x
ENV SKYWALKING_RELEASE_TAG v4.1.1
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib:/usr/local/lib64
ENV LD_RUN_PATH=$LD_RUN_PATH:/usr/local/lib:/usr/local/lib64

ENV PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ make gcc libc-dev php7-dev php7-pear pkgconf re2c pcre-dev zlib-dev"

RUN set -ex \
    && apk --update add --no-cache --virtual .build-deps $PHPIZE_DEPS git ca-certificates autoconf automake libtool g++ make file linux-headers file re2c pkgconf openssl openssl-dev curl-dev nginx \
    && echo "--- clone grpc ---" \
    && git clone --depth 1 -b ${GRPC_RELEASE_TAG} https://github.com/grpc/grpc /var/local/git/grpc \
    && cd /var/local/git/grpc \
    && git submodule update --init --recursive \
    && echo "--- download cmake ---" \
    && cd /var/local/git \
    && curl -L -o cmake-3.19.1.tar.gz  https://github.com/Kitware/CMake/releases/download/v3.19.1/cmake-3.19.1.tar.gz \
    && tar zxf cmake-3.19.1.tar.gz \
    && cd cmake-3.19.1 && ./bootstrap && make -j$(nproc) && make install \
    && echo "--- installing protobuf ---" \
    && cd /var/local/git/grpc/third_party/protobuf \
    && ./autogen.sh && ./configure && make -j$(nproc) && make install && make clean \
    && echo "--- installing grpc ---" \
    && cd /var/local/git/grpc \
    && mkdir -p cmake/build && cd cmake/build && cmake ../.. -DBUILD_SHARED_LIBS=ON -DgRPC_INSTALL=ON \
    && make -j$(nproc) && make install && make clean

# installing skywalking php

RUN echo "--- installing skywalking php ---" \
    && git clone --depth 1 -b ${SKYWALKING_RELEASE_TAG} https://github.com/SkyAPM/SkyAPM-php-sdk.git /var/local/git/skywalking \
    && cd /var/local/git/skywalking \
    && phpize && ./configure && make && make install \
    # config skywalking
    && { \
        echo "[skywalking]"; \
        echo "extension = skywalking.so"; \
        echo "skywalking.app_code = hello_skywalking"; \
        echo "skywalking.enable = 1"; \
        echo "skywalking.version = 8"; \
        echo "skywalking.grpc = 127.0.0.1:11800"; \
        # 把执行结果保存到 99-skywalking.ini 里面去
    } | tee /etc/php7/conf.d/99-skywalking.ini \
    && cd / \
    && apk del .build-deps \
    && apk del --purge *-dev \
    && rm -rf /var/cache/apk/* \
    && rm -fr /var/local/git