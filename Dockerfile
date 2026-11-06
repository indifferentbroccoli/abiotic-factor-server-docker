FROM --platform=linux/amd64 debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 \
    && apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        unzip \
        procps \
        libicu72 \
        xvfb \
        xauth \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.winehq.org/wine-builds/winehq.key \
        | gpg --dearmor -o /etc/apt/keyrings/winehq.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/winehq.gpg] https://dl.winehq.org/wine-builds/debian/ bookworm main" \
        > /etc/apt/sources.list.d/winehq.list \
    && apt-get update && apt-get install -y --install-recommends winehq-stable \
    && apt-get purge -y gnupg && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG DEPOT_DOWNLOADER_VERSION=3.4.0
RUN curl -fsSL \
    "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_${DEPOT_DOWNLOADER_VERSION}/DepotDownloader-linux-x64.zip" \
    -o /tmp/dd.zip && \
    mkdir -p /depotdownloader && \
    unzip /tmp/dd.zip DepotDownloader -d /depotdownloader && \
    chmod +x /depotdownloader/DepotDownloader && \
    rm /tmp/dd.zip

RUN useradd -m -u 1000 -s /bin/bash steam

LABEL maintainer="support@indifferentbroccoli.com" \
      name="indifferentbroccoli/abiotic-factor-server-docker" \
      github="https://github.com/indifferentbroccoli/abiotic-factor-server-docker" \
      dockerhub="https://hub.docker.com/r/indifferentbroccoli/abiotic-factor-server-docker"

ENV HOME=/home/steam \
    WINEARCH=win64 \
    WINEPREFIX=/home/steam/.wine \
    WINEDEBUG=-all \
    SERVER_DIR=/data/server-files \
    STEAM_BRANCH=public \
    UPDATE_ON_START=true \
    MAX_PLAYERS=6 \
    SERVER_NAME="Indifferent Broccoli Abiotic Factor Server" \
    WORLD_NAME=MyWorld \
    BACKUPS_TO_KEEP=2

COPY ./scripts /home/steam/server/

COPY branding /branding

RUN mkdir -p /data/server-files && \
    chmod 777 /home/steam /data/server-files && \
    chmod +x /home/steam/server/*.sh

USER steam

WORKDIR /home/steam/server

HEALTHCHECK --start-period=5m \
            CMD pgrep -f "AbioticFactorServer-Win64-Shipping" > /dev/null || exit 1

VOLUME ["/data/server-files"]

EXPOSE 7777/udp 27015/udp

ENTRYPOINT ["/home/steam/server/init.sh"]
