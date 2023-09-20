FROM alpine:3.17 AS builder

# Check required arguments exist. These will be provided by the Github Action
# Workflow and are required to ensure the correct branches are being used.
ARG SHAIRPORT_SYNC_BRANCH
RUN test -n "$SHAIRPORT_SYNC_BRANCH"
ARG SNAPCAST_BRANCH
RUN test -n "$SNAPCAST_BRANCH"
ARG NQPTP_BRANCH
RUN test -n "$NQPTP_BRANCH"

RUN apk -U add \
        alsa-lib-dev \
        autoconf \
        automake \
        avahi-dev \
        build-base \
        dbus \
        ffmpeg-dev \
        git \
        libconfig-dev \
        libgcrypt-dev \
        libplist-dev \
        libressl-dev \
        libsndfile-dev \
        libsodium-dev \
        libtool \
        mosquitto-dev \
        popt-dev \
        pulseaudio-dev \
        soxr-dev \
        xxd

##### ALAC #####
RUN git clone https://github.com/mikebrady/alac
WORKDIR /alac
RUN autoreconf -i
RUN ./configure
RUN make
RUN make install
WORKDIR /
##### ALAC END #####

##### NQPTP #####
RUN git clone https://github.com/mikebrady/nqptp
WORKDIR /nqptp
RUN git checkout "$NQPTP_BRANCH"
RUN autoreconf -i
RUN ./configure
RUN make
WORKDIR /
##### NQPTP END #####

##### SPS #####
RUN git clone https://github.com/mikebrady/shairport-sync
WORKDIR /shairport-sync
RUN git checkout "$SHAIRPORT_SYNC_BRANCH"
WORKDIR /shairport-sync/build
RUN autoreconf -i ../
RUN ../configure --sysconfdir=/etc --with-avahi --with-ssl=openssl --with-metadata --with-stdout
RUN make -j $(nproc)
RUN DESTDIR=install make install
WORKDIR /
##### SPS END #####

##### Snapcast #####
RUN apk add cmake boost-dev
RUN git clone https://github.com/badaix/snapcast
WORKDIR /snapcast
RUN git checkout "$SNAPCAST_BRANCH"
RUN mkdir build && cd build && cmake .. -DBUILD_CLIENT=ON -DBUILD_SERVER=ON -DBUILD_WITH_PULSE=OFF &&  cmake --build .
WORKDIR /
##### Snapcast End #####

# Shairport Sync Runtime System
FROM crazymax/alpine-s6:3.17-3.1.1.2

ENV S6_CMD_WAIT_FOR_SERVICES=1
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0

RUN apk -U add \
        alsa-lib \
        # avahi \
        # avahi-compat-libdns_sd \
        # avahi-dev \
        avahi-tools \
        dbus \
        ffmpeg \
        glib \
        less \
        less-doc \
        libconfig \
        libgcrypt \
        libplist \
        libpulse \
        libressl3.6-libcrypto \
        libsndfile \
        libsodium \
        libuuid \
        man-pages \
        mandoc \
        mosquitto \
        popt \
        soxr

# Copy build files.
COPY --from=builder /shairport-sync/build/install/usr/local/bin/shairport-sync /usr/local/bin/shairport-sync
COPY --from=builder /snapcast/bin/snapclient /usr/local/bin/snapclient
COPY --from=builder /snapcast/bin/snapserver /usr/local/bin/snapserver
COPY --from=builder /shairport-sync/build/install/usr/local/share/man/man7 /usr/share/man/man7
COPY --from=builder /nqptp/nqptp /usr/local/bin/nqptp
COPY --from=builder /usr/local/lib/libalac.* /usr/local/lib/
COPY --from=builder /shairport-sync/build/install/etc/shairport-sync.conf /etc/
COPY --from=builder /shairport-sync/build/install/etc/shairport-sync.conf.sample /etc/
# COPY --from=builder /shairport-sync/build/install/etc/dbus-1/system.d/shairport-sync-dbus.conf /etc/dbus-1/system.d/
# COPY --from=builder /shairport-sync/build/install/etc/dbus-1/system.d/shairport-sync-mpris.conf /etc/dbus-1/system.d/

# Create non-root user for running the container -- running as the user 'shairport-sync' also allows
# Shairport Sync to provide the D-Bus and MPRIS interfaces within the container

RUN addgroup shairport-sync
RUN adduser -D shairport-sync -G shairport-sync

# Add the shairport-sync user to the pre-existing audio group, which has ID 29, for access to the ALSA stuff
RUN addgroup -g 29 docker_audio && addgroup shairport-sync docker_audio && addgroup shairport-sync audio

# Remove anything we don't need.
RUN rm -rf /lib/apk/db/*

RUN apk add --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ librespot

# Add run script that will start SPS
COPY ./config/snapserver.conf /etc
COPY ./avahi-daemon.conf /etc/avahi
ADD ./cc_snapweb/build /usr/share/snapserver/snapweb/

COPY ./start.sh /

RUN chmod +x /start.sh

RUN echo "snapcast" > /etc/hostname

ENTRYPOINT ["/start.sh" ]

EXPOSE 1704 1705 1780



# WORKDIR /data

