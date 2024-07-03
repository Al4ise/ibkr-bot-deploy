#!/usr/bin/env bash

# Main menu
function main_menu() {
    echo "Please select an option:"
    echo "[1] Strategy"
    echo "[2] Gateway"
    echo "[0] Exit"

    read -p "Enter your choice: " choice
    echo
    case $choice in
        1)
            sudo docker logs $(sudo docker ps --filter "name=strategy" -q)
            read -n 1 -s -r -p "Press any key to continue..."
            echo
            main_menu
            ;;
        2)
            sudo docker logs $(sudo docker ps --filter "name=ib-gateway" -q)
            read -n 1 -s -r -p "Press any key to continue..."
            echo
            main_menu           
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            echo
            main_menu
            ;;
    esac
}

# Call the main menu function
main_menu