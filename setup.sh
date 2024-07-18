#!/usr/bin/env bash

dir="$(realpath "$(dirname "$0")")"
cd "$dir"

while [ "$choice" != "1" ] && [ "$choice" != "2" ]; do
  echo "Menu:"
  echo "[1] Trade Live"
  echo "[2] Trade Paper"
  echo "[3] Reset Credentials"
  echo "[4] Reset Configuration"

  read -rp "Enter your choice: " choice

  if [ "$choice" == "1" ]; then
      echo "[*] Will Deploy Live"
      PORT=4003

  elif [ "$choice" == "2" ]; then
      echo "[*] Will Deploy Paper"
      PORT=4004

  elif [ "$choice" == "3" ]; then
      rm -f "environment/.cred"
      echo "[*] Credentials Reset"

  elif [ "$choice" == "4" ]; then
      rm -f "environment/.pref"
      echo "[*] Settings Reset"

  else
      echo "Invalid choice. Exiting..."
      exit 1
      
  fi
done

# Make .cred if not available
if [ ! -e "environment/.cred" ]; then
  # Ask for IB Creds
  read -rp "Enter IBKR Username: " tws_userid
  read -rp "Enter IBKR Password: " tws_password

  echo "TWS_USERID=$tws_userid" >> environment/.cred
  echo "TWS_PASSWORD=$tws_password" >> environment/.cred

  # Ask for Alpaca Creds
  read -rp "Enter ALPACA_API_KEY: " alpaca_api_key
  read -rp "Enter ALPACA_API_SECRET: " alpaca_api_secret

  echo "ALPACA_API_KEY=$alpaca_api_key" >> environment/.cred
  echo "ALPACA_API_SECRET=$alpaca_api_secret" >> environment/.cred
fi

if [ ! -e "environment/.pref" ]; then
  read -rp "Enter Lumibot Strategy GitHub URL: " bot_repo
  echo "bot_repo=$bot_repo" >> environment/.pref
  #bot_repo="git@github.com:Lumiwealth-Strategies/options_condor_martingale.git"

  # Not To Touch the Values
  echo 'ALPACA_BASE_URL="https://paper-api.alpaca.markets/v2"' >> environment/.pref
  echo 'BROKER=IBKR' >> environment/.pref
  echo 'INTERACTIVE_BROKERS_IP=ib-gateway' >> environment/.pref
fi

printf "INTERACTIVE_BROKERS_PORT=$PORT\n" >> environment/.pref
if [ "$PORT" == 4003 ]; then
    printf "TRADING_MODE=live\n" >> environment/.pref
elif [ "$PORT" == 4004 ]; then
    printf "TRADING_MODE=paper\n" >> environment/.pref
fi

read -rp "Enter CONFIG_FILE: " config_file
echo "CONFIG_FILE=$config_file" >> environment/.pref
