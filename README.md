# Minecraft Paper Fabric
Hybrid Minecraft Server combining both Paper and Fabric using Velocity Proxy. It supports BlueMaps using one web UI for both servers and supports multi-paper worlds using the Multiverse Plugin.

## Versions: (1.21.6 in development)
 Currently updated for 1.21.5. (1.21.6 to come once BlueMaps releases their jar)
 V2.1 currently works for 1.21.6 and 1.21.5 (jars will need changing) this may work with other versions of Minecraft assuming plugins and mods are changed accordingly. However, they have not been tested.  
 
 To change to a different version, you must:
 1. Update Plugins and Mods located in the ```plugins/``` and ```mods/``` directories respectively to reflect the version you want to change to.
 2. Amend the docker compose file environment variables **VERSION** under the services ```MCPAPER``` and ```MCFABRIC``` to your chosen version.


## Overview
MC-Paper-Fabric is a Docker-based setup that enables a hybrid Minecraft server environment, integrating:
- **Paper Server**: For high-performance player optimised worlds, features plugin support. Good for things like player Hubs or vanilla Minecraft worlds.
- **Fabric Server**: For lightweight modding capabilities.
- **Velocity Proxy**: To route players between the two servers while only needing to connect to one.
- **BlueMaps:** A web-based map interface which combines the BlueMaps instances from both Paper and Fabric. Meaning players will only need to visit one web interface to access both server UIs.
- **RCON:** Allows for easy server management for both Paper and Fabric servers without the need to be on the Minecraft server directly.

This configuration allows players to connect through a single proxy and enjoy both plugin and mod functionalities.

## Features
- **Dual Server Integration:** Run both Paper and Fabric servers concurrently.

- **Velocity Proxy:** Directs player connections to the appropriate backend server.

- **BlueMaps:** Provides a unified, modern map interface for both servers.

- **Automated Backups:** Regular backups of server data to prevent data loss.

- **Dockerized Deployment:** Simplifies setup and management using Docker and Docker Compose.
- **RCON:** Allows for easy server management using standard Minecraft commands outside the Minecraft client.

## Repository Structure
```bash
MC-Paper-Fabric/
|- MCFABRIC-data/       # Fabric server configs and files
|- MCPAPER-data/        # Paper server configs and files
|- MCPROXY-data/        # Velocity proxy config files
|- MCPF-backups/        # Backup storage dir
|- backup/              # Backup scripts and Dockerfile
|- restore/             # Restore script and Docker compose file
|- configs/             # Default configs
|- mods/                # Fabric mods go here
|- plugins/             # Paper plugins go here
|- BlueMaps  /          # BlueMaps shared configuration (render files will go here)
|- docker-compose.yml   # Docker compose file
|- world-list.txt       # List of worlds to include in backups -> FABRIC WORLD MUST BE LAST
|- rcon-cli.sh          # Allows and admin to issue commands to either Minecraft servers
```

## Prerequisites
- [Docker](https://www.docker.com/get-started/)

- [Docker Compose](https://docs.docker.com/compose/install/)

## Setup Instructions

1. **Clone the Repository**
```bash
git clone https://github.com/Restfulbee37/MC-Paper-Fabric.git
cd MC-Paper-Fabric
```
2. **Add Mods and Plugins**
    - Place your Fabric mods in the ```mods/``` directory.
    - Place your Paper plugins in the ```plugins/``` directory.
3. **Configure Servers**
    - Update ```world-list.txt``` with the names of the worlds you wish to backup. **NOTE:** Your Fabric world **MUST** be the bottom of this list for this to work, see example in the file.
4. **Configure BlueMaps**
    - If you keep everything as default, it should work out of the box, BlueMaps will render automatically on server start.
    
    ### **If you change the world names:**
    - **For the Paper world:** Navigate to *BlueMaps/config/maps* and change the header *"world"* in each of the 'MCPAPER' configs to reflect your new world name.
    - **For the Fabric world:** Navigate to *MCFABRIC-data/config/bluemap/maps* and change the header *"world"* in the three fabric world config files to reflect your new world name.

    ### **If you have multiple Paper worlds using something like Multiverse:**
    1. Make sure these worlds are initialized i.e. you should have three seperate world files one for the overworld, one for the nether and one for the end. Paper will automatically do this when you create the new world.
    2. Clone the current **MCPAPER** config files located in *BlueMaps/config/maps* (these cloned files will be used for your second world).
    3. Change the name of these config files (these can be to whatever you want).
    4. Inside each cloned config file change the header *"world"* to reflect the directory name of your second world and change the header *"name"* to whatever you like (this will be what shows up in your BlueMaps UI).
    5. To have more than 2 Paper worlds, repeat **steps 1-4** for each world.
5. **Permissions**
    - Linux systems must set the file permissions for all volume directories to **1080**:
    ```chown -R 1080:1080 .```
6. **Start the Services**
    ```bash
    docker compose up -d
    ```
    This command will pull and build relevant Docker images and start the Velocity proxy, Paper server, Fabric server and the backup system.
7. **Navigate between servers**
    - To navigate between servers within Minecraft you would type in the commands shown below:
    ```php
    /server paper
    /server fabric
    ```

## BlueMaps
BlueMap is a program that reads your Minecraft world files and generates not only a map, but also 3D-models of the whole surface. With the web-app you then can look at those in your browser and basically view the world as if you were ingame.  
In this setup:
- Utilises BlueMaps on both servers to get live player updates for players in all servers.
- Merges both instances into one UI to make it easier to navigate for a user (similar to the legacy implementation using LiveAtlas with Dynmap).
- Live updates world changes and allows for a spectator style view.  

For more information on configuring multiple servers with BlueMaps, refer to the [BlueMaps Wiki](https://bluemap.bluecolored.de/wiki/getting-started/ServerNetworks.html).

## RCON CLI
RCON is an easy way to manage your Minecraft servers from the command line without the need to be directly logged into the Minecraft server.   
All commands in RCON are the same as you would get if you were on the server with OP privileges.   

A script has been written called *rcon-cli.sh* that will take an admin to the console of the requested server where they can issue commands as they would on the actual Minecraft server.
```bash
$ ./rcon-cli.sh -h
Usage: ./rcon-cli.sh [OPTION]

Options:
  -f, --fabric       Attaches to Fabric server RCON
  -p, --paper        Attaches to Paper server RCON
  -h, --help         Show this help message
```

An example usage would look like this:
```bash
$ ./rcon-cli.sh -p
Attaching to Paper RCON, type 'exit' to quit
> say Hello this is a demonstration of RCON!

> gamemode survival Restfulbee37
Set Restfulbee37 game mode to Survival Mode
> give Restfulbee37 minecraft:diamond_sword
Gave 1 [Diamond Sword] to Restfulbee37
> exit
RCON exited, welcome back!
$
```

## Backup and Restore System
An automated backup and restore system utilizing RCON and implemented in Docker:
- **Backups:** Regular backups are created and stored in the ```MCPF-backups/``` directory. The backup process includes:
    - Flushing world data to disk.
    - Archiving specified worlds listed in ```world-list.txt```.
    - Archiving plugin configurations and other world configs.
    - Storing backups with timestamps for easy retrieval and restoration.
- **Restore:** Restores can be conducted with:
```bash
cd restore
docker compose up
```
It will provide labelled error codes if any occur or give ***Exit code: 0*** if successful.

The backup and restore scripts are located in the ```backup/``` and ```restore/``` directories, respectively.

## Credits
- [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server) for the Docker images used for the Paper and Fabric servers.
- [PaperMC](https://papermc.io/) for the Paper Server.
- [FabricMC](https://fabricmc.net/) for the Fabric Server.
- [Velocity](https://papermc.io/software/velocity) for the Minecraft proxy.
- [BlueMaps](https://bluemap.bluecolored.de/) for the BlueMaps interactive world UI.

### Legacy Credits
- [Dynmap](https://github.com/webbukkit/dynmap) for the real-time map rendering.
- [LiveAtlas](https://github.com/JLyne/LiveAtlas) for the Dynmap web-based interface.

## License
This project is licensed under the MIT License. See the [LICENSE](https://github.com/Restfulbee37/MC-Paper-Fabric/blob/main/LICENSE.md) file for details.