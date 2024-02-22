FROM rust:slim-bookworm as builder
# Install librespot
RUN apt-get update && apt-get install -y curl build-essential cmake git libboost-all-dev libasound2-dev libpulse-dev libvorbisidec-dev libvorbis-dev libopus-dev libflac-dev libsoxr-dev alsa-utils libavahi-client-dev avahi-daemon libexpat1-dev autoconf python3-pip nano python3-websockets libpopt-dev libconfig-dev libssl-dev build-essential libavahi-client-dev vim-nox libplist-dev libsodium-dev libgcrypt-dev libavutil-dev libavcodec-dev libavformat-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*
#  && set -eux; \
#     curl -fsSL "https://api.github.com/repos/mikebrady/shairport-sync/releases/latest" | grep -oP '"tag_name": "\K(.*)(?=")' | xargs -I {} curl -fsSL "https://github.com/mikebrady/shairport-sync/archive/{}.tar.gz" -o shairport-sync.tar.gz; \
#     tar -xzf shairport-sync.tar.gz; \
#     cd shairport-sync-*; \
#     autoreconf -i -f; \
#     ./configure --with-stdout --with-avahi --with-ssl=openssl --with-metadata; \
#     make; \
#     cp shairport-sync /usr/local/bin/; \
    # cd ..; \
    # rm -rf shairport-sync* && \
    # apt-get remove -y curl autoconf libpopt-dev libconfig-dev libssl-dev build-essential libavahi-client-dev && \
    # apt-get autoremove -y && \


# Build and install librespot
# RUN git clone https://github.com/librespot-org/librespot.git
# RUN cd librespot && cargo build --release
# RUN cp /librespot/target/release/librespot /usr/local/bin/

# FROM debian:bullseye-slim

# Install Python dependencies including pip and websockets
RUN cargo install librespot
RUN git clone https://github.com/badaix/snapcast.git /snapcast
RUN cd /snapcast && mkdir build && cd build && cmake .. -DBUILD_CLIENT=OFF -DBUILD_SERVER=ON && cmake --build . && cp -r /snapcast/bin/* /usr/local/bin && cd / && rm -rf /snapcast
RUN git clone https://github.com/mikebrady/nqptp.git /nqptp && cd /nqptp && autoreconf -fi && ./configure --with-systemd-startup && make && cp nqptp /usr/local/bin/nqptp && cd .. && rm -rf nqptp
RUN git clone https://github.com/mikebrady/shairport-sync.git /shairport-sync && cd /shairport-sync && autoreconf -fi && ./configure --sysconfdir=/etc --with-stdout --with-avahi --with-ssl=openssl --with-systemd --with-airplay-2 --with-metadata && make && cp shairport-sync /usr/local/bin/shairport-sync && cd .. && rm -rf shairport-sync

RUN update-rc.d shairport-sync remove || true

# RUN python3 -m venv venv
# RUN ./venv/bin/python3 -m pip install websockets websocket-client
# RUN npm install --global yarn
# RUN export NVM_DIR="$HOME/.nvm"
# RUN curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash 
# RUN echo "[[ -s $HOME/.nvm/nvm.sh ]] && . $HOME/.nvm/nvm.sh" >> $HOME/.bashrc;
# RUN git clone https://github.com/daredoes/snapweb
# WORKDIR /snapweb
# RUN git checkout vite-to-gatsby
# RUN bash -i -c 'nvm install && nvm use && yarn && yarn build'


## Download snapweb compiled from github
RUN mkdir /tmp/snapweb && rm -rf /usr/share/snapserver/snapweb &&  mkdir /usr/share/snapserver && mkdir /usr/share/snapserver/snapweb && cd /tmp/snapweb && \
    curl -LJO https://github.com/daredoes/snapweb/releases/download/v0.4.1/dist.zip && \
    unzip dist.zip -d /usr/share/snapserver/snapweb && cd / && \
    rm -rf /tmp/snapweb

WORKDIR /data
WORKDIR /config

EXPOSE 1704
EXPOSE 1705
EXPOSE 1780



# COPY --from=builder /librespot/target/release/librespot /usr/local/bin/
COPY ./config/snapserver.conf /etc
COPY ./start.sh /
RUN chmod +x /start.sh


ENTRYPOINT [ "/start.sh" ]