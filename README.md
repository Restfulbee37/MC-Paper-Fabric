# Minecraft Paper Fabric
Hybrid Minecraft Server combining both Paper and Fabric using Velocity Proxy. It supports Dynmap using one web UI with LiveAtlas and supports multi-paper worlds using the Multiverse Plugin.

## Overview
MC-Paper-Fabric is a Docker-based setup that enables a hybrid Minecraft server environment, integrating:
- **Paper Server**: For high-performance player optimised worlds, features plugin support. Good for things like player Hubs or vanilla Minecraft worlds.
- **Fabric Server**: For lightweight modding capabilities.
- **Velocity Proxy**: To route players between the two servers while only needing to connect to one.
- **LiveAtlas:** A web-based map interface which combines the dynmap interfaces from both Paper and Fabric. Meaning players will only need to visit one web interface to access both Dynmap UIs.

This configuration allows players to connect through a single proxy and enjoy both plugin and mod functionalities.

## Features
- **Dual Server Integration:** Run both Paper and Fabric servers concurrently.

- **Velocity Proxy:** Directs player connections to the appropriate backend server.

- **LiveAtlas Mapping:** Provides a unified, modern map interface for both servers.

- **Nginx Reverse Proxy:** Serves LiveAtlas and merges multiple Dynmap instances.

- **Automated Backups:** Regular backups of server data to prevent data loss.

- **Dockerized Deployment:** Simplifies setup and management using Docker and Docker Compose.

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
|- live-atlas/          # LiveAtlas frontend
|- nginx/               # Nginx config file
|- docker-compose.yml   # Docker compose file
|- world-list.txt       # List of worlds to include in backups -> FABRIC WORLD MUST BE LAST
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
4. **Configure LiveAtlas and Nginx**
    - Update the index file at ```live-atlas/index.html``` under the ```servers``` section (Line: 67). Update the localhost domain to reflect your situation otherwise you will get **CORS** errors:
        - **External hosting;** Use your external IP address or domain
        - **Local Network but on a different system:** Use the internal IP of that system
        - **Your PC:** Leave at localhost
    - Nginx files in the ```nginx/``` directory shouldn't have to be changed as the IP addresses are for the internal Docker network not external.
5. **Permissions**
    - Linux systems must set the file permissions for all volume directories to **1080**:
    ```chown -R 1080:1080 .```
5. **Start the Services**
    ```bash
    docker compose up -d
    ```
    This command will pull and build relevant Docker images and start the Velocity proxy, Paper server, Fabric server, Nginx server, LiveAtlas and the backup system.
6. **Navigate between servers**
    - To navigate between servers within Minecraft you would type in the commands shown below:
    ```php
    /server paper
    /server fabric
    ```
7. **Start Dynmap Renders**
    - After world creation you must initialise the Dynmap render with the following commands:
    ```bash
    # Make sure you're in the relevant server
    /dynmap fullrender fabric # 'fabric' would be your fabric world name this is just an example
    /dynamp fullrender paper # 'paper' would be your paper world name this is also just an example
    ```

## LiveAtlas Integration with Dynmap
LiveAtlas provides a modern interface for viewing Minecraft worlds using the Dynmap backend.  
In this setup:
- Utilises Dynmap's MySQL database to read the backend of each instance.
- Nginx serves as a reverse proxy to stop CORS errors from the internal Docker network and to merge both Paper and Fabric servers.
- LiveAtlas is configured to display maps from both servers in the same interface.  

For more information on configuring multiple servers with LiveAtlas, refer to the [LiveAtlas Wiki](https://github.com/JLyne/LiveAtlas/wiki/Configuring-Multiple-Servers).

## Backup and Restore System
An automated backup and restore system is implemented using Docker:
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
It will provide labelled error codes if any occur or give *Exit code: 0* if successful.

The backup and restore scripts are located in the ```backup/``` and ```restore/``` directories, respectively.

## Credits
- [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server) for the Docker images used for the Paper and Fabric servers.
- [PaperMC](https://papermc.io/) for the Paper Server.
- [FabricMC](https://fabricmc.net/) for the Fabric Server.
- [Velocity](https://papermc.io/software/velocity) for the Minecraft proxy.
- [LiveAtlas](https://github.com/JLyne/LiveAtlas) for the Dynmap web-based interface.
- [Dynmap](https://github.com/webbukkit/dynmap) for the real-time map rendering.

## License
This project is licensed under the MIT License. See the [LICENSE](https://github.com/Restfulbee37/MC-Paper-Fabric/blob/main/LICENSE.md) file for details.