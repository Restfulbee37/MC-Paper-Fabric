#!/bin/bash

show_help() {
    echo "Usage: ./rcon-cli.sh [OPTION]"
    echo ""
    echo "Options:"
    echo "  -f, --fabric       Attaches to Fabric server RCON"
    echo "  -p, --paper        Attaches to Paper server RCON"
    echo "  -h, --help         Show this help message"
}

case "$1" in
    -f|--fabric)
        echo "Attaching to Fabric RCON, type 'exit' to quit"
        docker exec -it MCPFABRIC rcon-cli
        echo "RCON exited, welcome back!"
        ;;
    -p|--paper)
        echo "Attaching to Paper RCON, type 'exit' to quit"
        docker exec -it MCPAPERF rcon-cli
        echo "RCON exited, welcome back!"
        ;;
    -h|--help|"")
        show_help
        ;;
    *)
        echo "Invalid option: $1"
        show_help
        exit 1
        ;;
esac
