#!/usr/bin/env bash

main(){
    dir="$(realpath "$(dirname "$0")")"
    cd "$dir"
    getIBCredentials
    setupStrategies
}
# ask for username and password
getIBCredentials(){
    if [ ! -e "environment/.cred" ]; then
        # Ask for IB Creds
        read -rp "Enter IBKR Username: " tws_userid
        read -rp "Enter IBKR Password: " tws_password

        echo "TWS_USERID=$tws_userid" >> environment/.cred
        echo "TWS_PASSWORD=$tws_password" >> environment/.cred
    fi
}

setupStrategies(){
    while true; do
        echo "Menu:"
        echo "[1] Add Strategy"
        echo "[2] Remove Strategy"
        echo "[3] Reset Credentials"
        echo "[4] Reset Strategies"
        echo "[5] Done"

        read -rp "Enter your choice: " choice

        if [ "$choice" == "1" ]; then
            read -rp "Strategy Name: " strategy_name
            read -rp "Trading Mode (live or paper): " live_or_paper
            read -rp "Strategy GitHub Repo: " bot_repo
            read -rp "Database String (Optional): " db_str
            read -rp "Strategy Config File (Optional): " config_file
            read -rp "Discord Webhook URL (Optional): " webhook
            
            echo "${strategy_name,,},$live_or_paper,$bot_repo,$db_str,$config_file,$webhook" >> environment/.pref

        elif [ "$choice" == "2" ]; then
            echo "WIP"

        elif [ "$choice" == "3" ]; then
            rm -f "environment/.cred"
            echo "[*] Credentials Reset"

        elif [ "$choice" == "4" ]; then
            rm -f "environment/.pref"
            echo "[*] Strategies Reset"

        elif [ "$choice" == "5" ]; then
            return
        else
            echo "Invalid choice. Exiting..."
            exit 1
        fi
    done
}

main