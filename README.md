<!-- markdownlint-disable-next-line -->
![marketing_assets_banner](https://github.com/user-attachments/assets/b8b4ae5c-06bb-46a7-8d94-903a04595036)
[![GitHub License](https://img.shields.io/github/license/indifferentbroccoli/abiotic-factor-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/abiotic-factor-server-docker/blob/main/LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/indifferentbroccoli/abiotic-factor-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/abiotic-factor-server-docker/releases)
[![GitHub Repo stars](https://img.shields.io/github/stars/indifferentbroccoli/abiotic-factor-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/abiotic-factor-server-docker)
[![Discord](https://img.shields.io/discord/798321161082896395?style=for-the-badge&label=Discord&labelColor=5865F2&color=6aa84f)](https://discord.gg/indifferentbroccoli)
[![Docker Pulls](https://img.shields.io/docker/pulls/indifferentbroccoli/abiotic-factor-server-docker?style=for-the-badge&color=6aa84f)](https://hub.docker.com/r/indifferentbroccoli/abiotic-factor-server-docker)

Game server hosting

Fast RAM, high-speed internet

Eat lag for breakfast

[Try our Abiotic Factor server hosting free for 2 days!](https://indifferentbroccoli.com/abiotic-factor-server-hosting)

## Abiotic Factor Dedicated Server Docker

A Docker container for running an Abiotic Factor dedicated server. Server files are downloaded with
[DepotDownloader](https://github.com/SteamRE/DepotDownloader). The server binary is
Windows-only and runs via Wine.

## Server Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU      | 2 cores | 4+ cores    |
| RAM      | 4GB     | 8GB         |
| Storage  | 10GB    | 20GB        |

## How to use

Copy the .env.example file to a new file called .env. Then use either `docker compose` or `docker run`

> [!IMPORTANT]
> The server runs as user and group 1000, not root. The folder you mount must be owned by that user, for example `sudo chown -R 1000:1000 ./server-files`.
> To use a different id, set `user: "1001:1001"` in docker compose or `--user 1001:1001` with docker run, and give your folder to that id instead.

### Docker compose

```yaml
services:
  abioticfactor:
    image: indifferentbroccoli/abiotic-factor-server-docker
    restart: unless-stopped
    container_name: abioticfactor
    stop_grace_period: 60s
    ports:
      - 7777:7777/udp
      - 27015:27015/udp
    env_file:
      - .env
    volumes:
      - ./server-files:/data/server-files
```

Then run:

```bash
docker compose up -d
```

### Docker Run

```bash
docker run -d \
    --restart unless-stopped \
    --name abioticfactor \
    --stop-timeout 60 \
    -p 7777:7777/udp \
    -p 27015:27015/udp \
    --env-file .env \
    -v ./server-files:/data/server-files \
    indifferentbroccoli/abiotic-factor-server-docker
```

## Environment Variables

| Variable          | Default                                    | Info                                                                          |
|-------------------|--------------------------------------------|-------------------------------------------------------------------------------|
| SERVER_NAME       | Indifferent Broccoli Abiotic Factor Server | Name shown in the server browser                                              |
| SERVER_PASSWORD   |                                            | Password required to join. Leave empty for no password                        |
| MAX_PLAYERS       | 6                                          | Maximum number of players                                                     |
| WORLD_NAME        | MyWorld                                    | Name of the world save folder                                                 |
| UPDATE_ON_START   | true                                       | Download and validate server files on every startup. Set to `false` to skip  |
| STEAM_BRANCH      | public                                     | Steam branch to install                                                       |
| BACKUPS_TO_KEEP   | 2                                          | Number of world backups taken on startup to keep                              |
| MODS              |                                            | Optional: mod.io mod IDs separated by semicolons, e.g. `6411576;6366173`      |
| MODIO_TOKEN       |                                            | Optional: [mod.io access token](https://mod.io/me/access-tokens)              |

## Port Forwarding

Forward the following ports to your server:

* `7777/udp` - Game port
* `27015/udp` - Query port

## Support

For issues and questions:
* GitHub Issues: [Report an issue](https://github.com/indifferentbroccoli/abiotic-factor-server-docker/issues)
* Game Server Hosting: [indifferentbroccoli.com](https://indifferentbroccoli.com)
