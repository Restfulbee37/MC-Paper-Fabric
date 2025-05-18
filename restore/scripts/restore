#!/bin/bash

echo "Initiating Restore Container"
echo "Exit codes:"
echo "exit 0: Restore was completed successfully"
echo "INFO 3: No backup files were found"
echo "INFO 2: No backup or world files were found - A new world will be created"
echo "exit 1: Restore failed"
echo "exit (anything else): Unknown error"

# Define vars
BACKUP_DIR="${BACKUP_DIR:-/backups}"
PLUGIN_DIR="${PLUGIN_DIR:-/plugins}"
PAPER_DATA_DIR="${PAPER_DATA_DIR:-/PAPER-data}"
FABRIC_DATA_DIR="${FABRIC_DATA_DIR:-/FABRIC-data}"
WORLD_LIST="${WORLD_LIST:-/worlds.txt}"
TMP_DIR="${TMP_DIR:-/tmp_store}"

# Read world names into array
echo "worldlist $WORLD_LIST"
worlds=()
while IFS= read -r line || [ -n "$line" ]; do
    [ -n "$line" ] && worlds+=("$line")
done < "$WORLD_LIST"

# Check if world list is empty
if [ "${#worlds[@]}" -eq 0 ]; then
    echo "No worlds found in $WORLD_LIST"
    exit 1
fi

# Extract last world to FABRIC, others to PAPER
last_index=$((${#worlds[@]} - 1))
fabric_world="${worlds[$last_index]}"
unset 'worlds[$last_index]'
paper_worlds=("${worlds[@]}")

echo "PAPER worlds: ${paper_worlds[*]}"
echo "FABRIC world: $fabric_world"
echo "PAPER data dir: $PAPER_DATA_DIR"
echo "FABRIC data dir: $FABRIC_DATA_DIR"

# Find latest backup file
latest_backup_file=$(ls -t "$BACKUP_DIR" 2>/dev/null | head -n1)

# Check for available backups
if [[ -z "$latest_backup_file" ]]; then
    echo "INFO 3"
    exit 0
fi

# Copy and extract backup
mkdir /restore$TMP_DIR
cp "$BACKUP_DIR/$latest_backup_file" "/restore$TMP_DIR/"
tar -xvzf "/restore$TMP_DIR/$latest_backup_file" -C "/restore$TMP_DIR/" > /dev/null
echo "Restoring $latest_backup_file!"
rm "/restore$TMP_DIR/$latest_backup_file"

# Verify extracted data exists
for world in "${paper_worlds[@]}" "$fabric_world"; do
    world_path="/restore$TMP_DIR/mc-bk/backup/$world"
    if [ ! -d "$world_path" ] || [ -z "$(ls -A "$world_path" 2>/dev/null)" ]; then
        echo "Missing or empty world data: $world"
        exit 1
    fi
done

# Clean PAPER world directories
for world in "${paper_worlds[@]}"; do
    target_dir="$PAPER_DATA_DIR/$world"
    mkdir -p "$target_dir"
    find "$target_dir" -mindepth 1 -delete
done

# Clean FABRIC world directory
target_dir="$FABRIC_DATA_DIR/$fabric_world"
mkdir -p "$target_dir"
find "$target_dir" -mindepth 1 -delete

# Copy PAPER world data
for world in "${paper_worlds[@]}"; do
    cp -R "/restore$TMP_DIR/mc-bk/backup/$world/"* "$PAPER_DATA_DIR/$world/"
    chmod -R 777 "$PAPER_DATA_DIR/$world"
    echo "Copied $world to PAPER"
done

# Copy FABRIC world data
cp -R "/restore$TMP_DIR/mc-bk/backup/$fabric_world/"* "$FABRIC_DATA_DIR/$fabric_world/"
chmod -R 777 "$FABRIC_DATA_DIR/$fabric_world"
echo "Copied $fabric_world to FABRIC"

# Copy plugin data
cp -r "/restore$TMP_DIR/mc-bk/backup/plugins/"* "$PLUGIN_DIR/"
chmod -R 777 "$PLUGIN_DIR/Multiverse-Inventories"

# Clean up
find "/restore$TMP_DIR/" -mindepth 1 -delete

echo "Restore Completed Successfully!"
exit 0
