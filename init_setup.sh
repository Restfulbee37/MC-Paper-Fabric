#!/bin/bash

JARS_FILE=".setup_config/jars.json"
MODS_DIR="./mods"
PLUGINS_DIR="./plugins"

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