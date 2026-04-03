# FortressCraft-Evolved-Docker-Server



## Usage

I recommend reading this Article first https://steamcommunity.com/sharedfiles/filedetails/?id=788739671

### Quick Start

Clone the repo: 
```bash
git clone "https://github.com/Dakes/FortressCraft-Evolved-Docker-Server.git"
cd FortressCraft-Evolved-Docker-Server
```

Change the folling files to your needs:
```bash
docker-compose.yml
files/firstrun.ini
files/serveroverrides.ini
```

The repo now includes a local `.env` for machine-specific defaults, and `.env.example` as the tracked template. Edit `.env` for local paths, uid/gid, and startup behavior.

You may need to create the necessary directories yourself, like in this case
```bash
~/games/FCE/
~/games/FCE_server/
```

Relevant `.env` values:
```bash
FCE_DATA_DIR=~/games/FCE
FCE_SERVER_DIR=~/games/FCE_server
PUID=845
PGID=845
UPDATE_ON_START=true
UPDATE_MODS_ON_START=true
```

To build the image: (in the same folder as docker-compose.yml)
```bash
docker compose build
```

To start it:
```bash
docker compose up -d
```

Or both commands in one: 
```bash
docker compose up -d --build
```


### Notes

It may take some time until the server got downloaded the first time. It is ~5gb in size.  

If you use the volume:
```YAML
- ~/games/FCE_server:/opt/FCE
```
The 5gb server will be saved in `~/games/FCE_server` rather than inside the docker. 
It will be revalidated and updated after future rebuilds of the container, without the need to redownload all ~5gb.  


### Mods

To set up your server with mods, just follow the steps in this Article:
https://steamcommunity.com/sharedfiles/filedetails/?id=788739671

The necessary directories will be the following:
```
~/games/FCE/Worlds/
~/games/FCE/WorkshopMods/
```
