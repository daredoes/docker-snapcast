FROM rust:slim-bookworm as shared
RUN apt-get update && apt-get install -y curl build-essential cmake autoconf git libboost-all-dev libasound2-dev libpulse-dev libvorbisidec-dev libvorbis-dev libopus-dev libflac-dev libsoxr-dev alsa-utils libavahi-client-dev avahi-daemon libexpat1-dev python3-pip nano python3-websockets libpopt-dev libconfig-dev libssl-dev build-essential libavahi-client-dev zip vim-nox libplist-dev libsodium-dev libgcrypt-dev libavutil-dev libavcodec-dev libavformat-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*
FROM shared as librespot-builder
RUN cargo install librespot

FROM shared as shairport-builder
RUN git clone https://github.com/mikebrady/shairport-sync.git /shairport-sync && cd /shairport-sync && autoreconf -fi && ./configure --sysconfdir=/etc --with-stdout --with-avahi --with-ssl=openssl --with-systemd --with-airplay-2 --with-metadata && make && cp shairport-sync /usr/local/bin/shairport-sync && cd .. && rm -rf shairport-sync
FROM shared as nqptp-builder
RUN git clone https://github.com/mikebrady/nqptp.git /nqptp && cd /nqptp && autoreconf -fi && ./configure --with-systemd-startup && make && cp nqptp /usr/local/bin/nqptp && cd .. && rm -rf nqptp
FROM shared as snapcast-builder
RUN git clone https://github.com/badaix/snapcast.git /snapcast
RUN cd /snapcast && mkdir build && cd build && cmake .. -DBUILD_CLIENT=OFF -DBUILD_SERVER=ON && cmake --build . && cp -r /snapcast/bin/* /usr/local/bin && mkdir -p /usr/share/snapserver/plug-ins && cp -r /snapcast/server/etc/plug-ins/* /usr/share/snapserver/plug-ins && cd / && rm -rf /snapcast
RUN update-rc.d shairport-sync remove || true
FROM debian:bookworm-slim as base
RUN apt-get update && apt-get install -y --no-install-recommends curl libasound2-dev libpulse-dev libvorbisidec-dev libvorbis-dev libopus-dev libflac-dev libsoxr-dev alsa-utils libavahi-client-dev avahi-daemon libexpat1-dev python3 nano python3-websockets libpopt-dev libconfig-dev libssl-dev libavahi-client-dev unzip vim-nox libplist-dev libsodium-dev libgcrypt-dev libavutil-dev libavcodec-dev libavformat-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/\* /var/tmp/*
FROM base
# RUN apt-get update && apt-get install -y --no-install-recommends curl git libboost-all-dev libasound2-dev libpulse-dev libvorbisidec-dev libvorbis-dev libopus-dev libflac-dev libsoxr-dev alsa-utils libavahi-client-dev avahi-daemon libexpat1-dev python3-pip nano python3-websockets libpopt-dev libconfig-dev libssl-dev libavahi-client-dev unzip vim-nox libplist-dev libsodium-dev libgcrypt-dev libavutil-dev libavcodec-dev libavformat-dev \
#     && apt-get clean && \
#     rm -rf /var/lib/apt/lists/* /tmp/\* /var/tmp/*
RUN update-rc.d shairport-sync remove || true
# Install Python dependencies including pip and websockets

# RUN python3 -m venv venv
# RUN python3 -m pip install websockets websocket-client
# RUN npm install --global yarn
# RUN export NVM_DIR="$HOME/.nvm"
# RUN curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash 
# RUN echo "[[ -s $HOME/.nvm/nvm.sh ]] && . $HOME/.nvm/nvm.sh" >> $HOME/.bashrc;
# RUN git clone https://github.com/daredoes/snapweb
# WORKDIR /snapweb
# RUN git checkout vite-to-gatsby
# RUN bash -i -c 'nvm install && nvm use && yarn && yarn build'


## Download snapweb compiled from github

EXPOSE 1704
EXPOSE 1705
EXPOSE 1780

COPY ./config/snapserver.conf /etc
COPY ./start.sh /
RUN chmod +x /start.sh

WORKDIR /usr/share/snapserver

COPY --from=shairport-builder /usr/local/bin/shairport-sync /usr/local/bin/shairport-sync
COPY --from=snapcast-builder /usr/local/bin/snapserver /usr/local/bin/snapserver
COPY --from=snapcast-builder /usr/share/snapserver/plug-ins/ /usr/share/snapserver/plug-ins/
COPY --from=nqptp-builder /usr/local/bin/nqptp /usr/local/bin/nqptp
COPY --from=librespot-builder /usr/local/cargo/bin/librespot /usr/local/bin/librespot

RUN curl -LJO https://github.com/daredoes/snapweb/releases/download/v0.5.0/dist.zip && unzip dist.zip -d /usr/share/snapserver/snapweb


ENTRYPOINT [ "/start.sh" ]