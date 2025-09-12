#!/bin/bash

JARS_FILE=".setup_config/jars.json"
MODS_DIR="./mods"
PLUGINS_DIR="./plugins"
DOCKER_COMPOSE_FILE="docker-compose.yml"

read -p "Enter your Minecraft Version (e.g: 1.21.5): " MC_VERSION

if jq -e --arg v "$MC_VERSION" 'has($v)' "$JARS_FILE" > /dev/null; then
    echo "Minecraft version $MC_VERSION is supported."
else
    echo "Error: Minecraft version $MC_VERSION is not supported."
    exit 1
fi

mkdir -p "$MODS_DIR" "$PLUGINS_DIR"

echo "Downloading Mods and Plugins for version $MC_VERSION..."

jq -r --arg v "$MC_VERSION" '.[$v] | to_entries[] | "\(.key)\t\(.value)"' "$JARS_FILE" \
| while IFS=$'\t' read -r subkey url; do
    if [[ $subkey == *paper ]]; then
        dest="$PLUGINS_DIR"
    else
        dest="$MODS_DIR"
    fi

    echo "$subkey: Downloading from $url to $dest"

    if ! wget -N --show-progress -P "$dest" "$url"; then
        echo "Error downloading $subkey from $url" >&2
        exit 1
    fi
done

echo "All mods and plugins downloaded successfully."

echo "Editing Docker Compose file..."
if [[ -f "$DOCKER_COMPOSE_FILE" ]]; then
    echo "Setting Minecraft version to $MC_VERSION in $DOCKER_COMPOSE_FILE"
    sed -i -E "s/(VERSION:[[:space:]]*).*/\1$MC_VERSION/" "$DOCKER_COMPOSE_FILE"

    read -p "Select your difficulty (peaceful, easy, normal, hard) [default: easy]: " DIFFICULTY
    DIFFICULTY=${DIFFICULTY:-easy}
    if [[ "$DIFFICULTY" =~ ^(peaceful|easy|normal|hard)$ ]]; then
        echo "Setting difficulty to $DIFFICULTY in $DOCKER_COMPOSE_FILE"
        sed -i -E "s/(DIFFICULTY:[[:space:]]*).*/\1$DIFFICULTY/" "$DOCKER_COMPOSE_FILE" 
    else
        echo "Invalid difficulty. Using default: easy"
        sed -i -E "s/(DIFFICULTY:[[:space:]]*).*/\1easy/" "$DOCKER_COMPOSE_FILE"
    fi

    read -p "Select your game mode (survival, creative, adventure, spectator) [default: survival]: " GAMEMODE
    GAMEMODE=${GAMEMODE:-survival}
    if [[ "$GAMEMODE" =~ ^(survival|creative|adventure|spectator)$ ]]; then
        echo "Setting game mode to $GAMEMODE in $DOCKER_COMPOSE_FILE"
        sed -i -E "s/(MODE:[[:space:]]*).*/\1$GAMEMODE/" "$DOCKER_COMPOSE_FILE"
    else
        echo "Invalid game mode. Using default: survival"
        sed -i -E "s/(MODE:[[:space:]]*).*/\1survival/" "$DOCKER_COMPOSE_FILE"
    fi  

    read -p "Enter your minecraft username for lvl 4 ops (leave blank for none): " MC_USERNAME
    if [[ -n "$MC_USERNAME" ]]; then
        echo "Setting OP username to $MC_USERNAME in $DOCKER_COMPOSE_FILE"
        sed -i -E "s/(OPS:[[:space:]]*).*/\1\"$MC_USERNAME\"/" "$DOCKER_COMPOSE_FILE"
    else
        echo "No OP username provided. Leaving blank."
        sed -i -E "s/(OPS:[[:space:]]*).*/\1\"\"/" "$DOCKER_COMPOSE_FILE"
    fi

    read -p "Enable hardcore mode for FABRIC? (true/false) [default: false]: " HARDCORE_FABRIC
    read -p "Enable hardcore mode for PAPER?  (true/false) [default: false]: " HARDCORE_PAPER

    HARDCORE_FABRIC=${HARDCORE_FABRIC:-false}
    HARDCORE_PAPER=${HARDCORE_PAPER:-false}

    valid_bool() { [[ "$1" =~ ^(true|false)$ ]]; }
    valid_bool "$HARDCORE_FABRIC" || HARDCORE_FABRIC=false
    valid_bool "$HARDCORE_PAPER"  || HARDCORE_PAPER=false

    if ! command -v yq >/dev/null 2>&1; then
        echo "ERROR: 'yq' is required but not installed. Please install 'yq' to proceed. Setting HARDCORE to false by default."
        sed -i -E "s/(HARDCORE:[[:space:]]*).*/\1false/" "$DOCKER_COMPOSE_FILE"
    else
        echo "Updating HARDCORE for paper and fabric in $DOCKER_COMPOSE_FILE ..."
        yq -i "
            .services.MCFABRIC.environment.HARDCORE = ${HARDCORE_FABRIC} |
            .services.MCPAPER.environment.HARDCORE  = ${HARDCORE_PAPER}
        " "$DOCKER_COMPOSE_FILE"
    fi

    read -p "Enter backup interval in minutes (default 60): " BACKUP_INTERVAL
    BACKUP_INTERVAL=${BACKUP_INTERVAL:-60}
    if [[ "$BACKUP_INTERVAL" =~ ^[0-9]+$ ]]; then
        echo "Setting backup interval to $BACKUP_INTERVAL minutes in $DOCKER_COMPOSE_FILE"
        sed -i -E "s/(BACKUP_INTERVAL:[[:space:]]*).*/\1$BACKUP_INTERVAL/" "$DOCKER_COMPOSE_FILE"
    else
        echo "Invalid input. Using default: 60 minutes"
        sed -i -E "s/(BACKUP_INTERVAL:[[:space:]]*).*/\160/" "$DOCKER_COMPOSE_FILE"
    fi

    
else
    echo "Error: $DOCKER_COMPOSE_FILE not found!"
    exit 1
fi