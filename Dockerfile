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

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg unzip procps \
        lib32gcc-s1 lib32stdc++6 libgnutls30 \
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
    && mkdir -p /opt/steamcmd /data/server-data \
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

ENV SERVER_DIR=/data/server-data

WORKDIR /data/server-data

HEALTHCHECK --start-period=5m \
   CMD pgrep "AbioticFactorServer-Win64-Shipping" > /dev/null || exit 1

VOLUME ["/data/server-data"]
EXPOSE 7777/udp 27015/udp

ENTRYPOINT ["/usr/bin/bash", "--", "/home/steam/server/init.sh"]