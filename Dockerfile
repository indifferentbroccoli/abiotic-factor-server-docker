FROM golang:1.23.1-alpine AS rcon-cli_builder

ARG RCON_VERSION="0.10.3"
ARG RCON_TGZ_SHA1SUM=33ee8077e66bea6ee097db4d9c923b5ed390d583

WORKDIR /build

# install rcon
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

ENV CGO_ENABLED=0
RUN wget -q https://github.com/gorcon/rcon-cli/archive/refs/tags/v${RCON_VERSION}.tar.gz -O rcon.tar.gz \
    && echo "${RCON_TGZ_SHA1SUM}" rcon.tar.gz | sha1sum -c - \
    && tar -xzvf rcon.tar.gz \
    && rm rcon.tar.gz \
    && mv rcon-cli-${RCON_VERSION}/* ./ \
    && rm -rf rcon-cli-${RCON_VERSION} \
    && go build -v ./cmd/gorcon

FROM debian:bookworm-slim

LABEL maintainer="support@indifferentbroccoli.com" \
      name="indifferentbroccoli/abiotic-factor-server-docker" \
      github="https://github.com/indifferentbroccoli/abiotic-factor-server-docker" \
      dockerhub="https://hub.docker.com/r/indifferentbroccoli/abiotic-factor-server-docker"

ENV DEBIAN_FRONTEND=noninteractive \
    WINEARCH=win64 \
    WINEPREFIX=/home/steam/.wine \
    WINEDEBUG=-all \
    XDG_RUNTIME_DIR=/tmp/runtime-steam

COPY --from=rcon-cli_builder /build/gorcon /usr/bin/rcon-cli

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg unzip procps \
        lib32gcc-s1 lib32stdc++6 libgnutls30 jq \
    && apt-get install -y --no-install-recommends xvfb xauth \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.winehq.org/wine-builds/winehq.key \
        | gpg --dearmor -o /etc/apt/keyrings/winehq.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/winehq.gpg] https://dl.winehq.org/wine-builds/debian/ bookworm main" \
        > /etc/apt/sources.list.d/winehq.list \
    && apt-get update \
    && apt-get install -y --install-recommends winehq-stable \
    && apt-get install -y cabextract winbind screen xvfb \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash steam \
    && mkdir -p /opt/steamcmd /data/server \
    && curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
        | tar -xz -C /opt/steamcmd \
    && chown -R steam:steam /opt/steamcmd /data

COPY --chown=steam:steam ./scripts /home/steam/server/
RUN chmod +x /home/steam/server/*.sh

COPY branding /branding

RUN mkdir -p /tmp/runtime-steam \
    && chown steam:steam /tmp/runtime-steam \
    && chmod 700 /tmp/runtime-steam

USER steam

RUN /opt/steamcmd/steamcmd.sh +quit || true \
    && wineboot --init && wineserver -w

ENV SERVER_DIR=/data/server

WORKDIR /data/server
#HEALTHCHECK --start-period=5m \
#    CMD pgrep "AbioticFactor" > /dev/null || exit 1

VOLUME ["/data/server"]
EXPOSE 7777/udp 27015/udp 27020/tcp

ENTRYPOINT ["/usr/bin/bash", "--", "/home/steam/server/init.sh"]