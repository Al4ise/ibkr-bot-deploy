#!/usr/bin/env bash

main(){
    dir="$(realpath "$(dirname "$0")")"
    cd "$dir" || exit
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

        case $choice in
            1)
                read -rp "Strategy Name: " strategy_name
                read -rp "Trading Mode (live or paper): " live_or_paper
                read -rp "Strategy GitHub Repo: " bot_repo
                read -rp "Database String (Optional): " db_str
                read -rp "Strategy Config File (Optional): " config_file
                read -rp "Discord Webhook URL (Optional): " webhook
                read -rp "IB Subaccount (Optional): " ib_subaccount
                
                echo "${strategy_name,,},$live_or_paper,$bot_repo,$db_str,$config_file,$webhook,$ib_subaccount" >> environment/.pref
                ;;

            2)
                echo "WIP"
                ;;

            3)
                rm -f "environment/.cred"
                echo "[*] Credentials Reset"
                ;;

            4)
                rm -f "environment/.pref"
                echo "[*] Strategies Reset"
                ;;

            5)
                return
                ;;

            *)
                echo "Invalid choice. Exiting..."
                exit 1
                ;;
        esac
    done
}

main