#!/bin/bash

# Sets defualt values if not specified
BACKUP_INTERVAL="${BACKUP_INTERVAL:-30m}"
BACKUP_NAME="${BACKUP_NAME:-MC-SERVER-BACKUP}"
INITIAL_DELAY="${INITIAL_DELAY:-5m}"
PAPER_RCON_HOST="${PAPER_RCON_HOST:-minecraft-server}"
PAPER_RCON_PORT="${PAPER_RCON_PORT:-25575}"
PAPER_RCON_PASSWORD="${PAPER_RCON_PASSWORD:-rcon}"
FABRIC_RCON_HOST="${FABRIC_RCON_HOST:-minecraft-server}"
FABRIC_RCON_PORT="${FABRIC_RCON_PORT:-25576}"
FABRIC_RCON_PASSWORD="${FABRIC_RCON_PASSWORD:-rcon}"
PRUNE_BACKUP_DAYS="${PRUNE_BACKUP_DAYS:-7}"
PAPER_SERVER_PORT="${PAPER_SERVER_PORT:-"25565"}"
FABRIC_SERVER_PORT="${FABRIC_SERVER_PORT:-"25567"}"
DEST_DIR="${DEST_DIR:-/backups}"
PAPER_SRC_DIR="${PAPER_SRC_DIR:-/data}"
FABRIC_SRC_DIR="${FABRIC_SRC_DIR:-/data}"
PLUGIN_DIR="${PLUGIN_DIR:-/plugins}"

# Function to sleep scripts
script_sleep() {
	local time="$1"
	sleep $time
}

# Function to send RCON commands
send_rcon_command() {
	local command="$1"
	/opt/rcon-cli --host $PAPER_RCON_HOST --port $PAPER_RCON_PORT --password $PAPER_RCON_PASSWORD $command > /dev/null
	/opt/rcon-cli --host $FABRIC_RCON_HOST --port $FABRIC_RCON_PORT --password $FABRIC_RCON_PASSWORD $command > /dev/null

}

# Function that will remove unnessesary files that do not need backing up, relies on world-list.txt
remove_files() {
	cd /mc-bk/backup || { echo "Directory not found!"; exit 1; }

	# Read world-list.txt into an array
	mapfile -t keep < /world-list.txt

	# Start building the find command
	find_cmd="find . -mindepth 1"

	for name in "${keep[@]}"; do
		find_cmd+=" ! -path \"*/$name\" ! -path \"*/$name/*\""
	done

	# Manually add extra directories
	find_cmd+=" ! -path '.$PAPER_SRC_DIR' ! -path '.$PAPER_SRC_DIR/*'"
	find_cmd+=" ! -path '.$FABRIC_SRC_DIR' ! -path '.$FABRIC_SRC_DIR/*'"
	find_cmd+=" ! -path '.$PLUGIN_DIR/Multiverse-Inventories' ! -path '.$PLUGIN_DIR/Multiverse-Inventories/*'"

	# Perform deletion
	echo "Deleting all files and directories except those in world-list.txt..."
	eval "$find_cmd -exec rm -rf {} +"
}

# Function that will retrieve mc world from volume
do_file_things() {
	rm -rf /mc-bk/backup && mkdir /mc-bk/backup && cd /mc-bk/backup
	current_date_time=$(date +"%Y-%m-%d_%H-%M-%S")
	filename="${BACKUP_NAME}-${current_date_time}.tar.gz"
	cp -r $PAPER_SRC_DIR/* /mc-bk/backup
	cp -r $FABRIC_SRC_DIR/* /mc-bk/backup
	
	# Remove unnessesary files
	remove_files

	cp -r $PLUGIN_DIR/Multiverse-Inventories /mc-bk/backup$PLUGIN_DIR

	echo "Compressing world"
	tar -czvf "$filename" /mc-bk/backup  > /dev/null
	echo "Complete! Moving world to backup folder..."
	chmod 700 "$filename"
	mv "$filename" "$DEST_DIR"
	cd / && rm -rf /mc-bk/backup
}

# Function in case of crash/ docker killed
cleaup() {
	echo "Shutting down"
	/opt/rcon-cli --host $RCON_HOST --port $RCON_PORT --password $RCON_PASSWORD "save-on" > /dev/null
	exit 0
}

#Extract number from env var and get seconds
BACKUP_INTERVAL_SECONDS=$(( $(echo "$BACKUP_INTERVAL" | grep -o '[0-9]' | tr -d '\n') * 60 ))
INITIAL_DELAY_SECONDS=$(( $(echo "$INITIAL_DELAY" | grep -o '[0-9]' | tr -d '\n') * 60 ))

#Initial Delay
script_sleep $INITIAL_DELAY_SECONDS

#Ensures autosave is always on
trap cleanup SIGTERM

#Main loop
while true
do
	# Sleeps the script for the specified interval
	script_sleep $BACKUP_INTERVAL_SECONDS
	# Check server is running
	# ping -c 5 ${PAPER_RCON_HOST} > /dev/null || {
	# 	echo "PAPER is down, exiting"
	# 	break
	# }
	# ping -c 5 ${FABRIC_RCON_HOST} > /dev/null || {
	# 	echo "FABRIC is down, exiting"
	# 	break
	# }
	# Turns off autosave
	send_rcon_command "save-off"
	# Saves the game
	send_rcon_command "save-all flush"
	script_sleep 10
	# Backs up the world and moves it to backups
	do_file_things
	# Turns autosave back on
	send_rcon_command "save-on"
	echo "Pruning Old Backups"
	find "$DEST_DIR" -type f -mtime +$(expr $PRUNE_BACKUP_DAYS - 1) -exec rm {} \;
	echo "Backup Complete!, Sleeping '$BACKUP_INTERVAL'"
done
