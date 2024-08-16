#!/usr/bin/env bash

# Main menu
function main_menu() {
    echo "Please select an option:"
    echo "[1] Strategy"
    echo "[2] Gateway"
    echo "[0] Exit"

    read -p "Enter your choice: " choice
    case $choice in
        1)
            menu_strategies=()

            # get all strategies from .pref and make a menu that picks one strategy name
            while IFS= read -r strategy; do
                IFS=',' read -r strategy_name _ <<< "$strategy"
                menu_strategies+=( "$strategy_name" )
            done < "environment/.pref"

            echo "Select a strategy:"
            
            for i in "${!menu_strategies[@]}"; do
                echo "[$((i+1))] ${menu_strategies[$i]}"
            done

            read -rp "Select Strategy: : " choice

            selected_strategy="${menu_strategies[$((choice-1))]}"
            echo "You selected: $selected_strategy"

            sudo docker logs "$(sudo docker ps --filter "name=$selected_strategy" -q)"
            read -n 1 -s -r -p "Press any key to continue..."
            echo
            main_menu
            ;;
        2)
            sudo docker logs "$(sudo docker ps --filter "name=ib-gateway" -q)"
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