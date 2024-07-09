#!/usr/bin/env bash
set -e

dir="$(realpath "$(dirname "$0")")"
OS="$(uname)"

# cleanup
cleanup() {
    echo "Performing cleanup..."
    rm -rf "$dir/environment/bot"
}

# Set up exit trap
cleanup
trap cleanup EXIT SIGINT SIGTERM

# .env setup
cd "$dir"

# free ports
sudo docker ps --format "{{.Names}}" | grep 'strategy' | xargs -r sudo docker kill > /dev/null
sudo docker ps --format "{{.Names}}" | grep 'ib-gateway' | xargs -r sudo docker kill > /dev/null

# reset .env if any
rm -f "$dir/.env"

while [ "$choice" != "1" ] && [ "$choice" != "2" ]; do
  echo "Menu:"
  echo "[1] Trade Live"
  echo "[2] Trade Paper"
  echo "[3] Trade Both [WIP]"
  echo "[4] Reset Credentials"
  echo "[5] Reset Configuration"
  echo "[6] Delete all Docker images"
  echo "[7] Delete the Docker images of strategies only"
  
  read -rp "Enter your choice: " choice

  if [ "$choice" == "1" ]; then
      echo "[*] Will Deploy Live"
      printf "TRADING_MODE=live\n" >> .env
      PORT=4003

  elif [ "$choice" == "2" ]; then
      printf "TRADING_MODE=paper\n" >> .env
      PORT=4004
      echo "[*] Will Deploy Paper"

  elif [ "$choice" == "3" ]; then
      printf "TRADING_MODE=both\n" >> .env
      PORT=4004
      echo "[*] Will Deploy Both"

  elif [ "$choice" == "4" ]; then
      rm -f "environment/.cred"
      echo "[*] Credentials Reset"

  elif [ "$choice" == "5" ]; then
      rm -f "environment/.pref"
      echo "[*] Settings Reset"

  elif [ "$choice" == "6" ]; then
      sudo docker system prune -a -f --volumes
      echo "[*] Done"

  elif [ "$choice" == "7" ]; then
      sudo docker images --format "{{.Repository}}" | grep "strategy" | xargs -r sudo docker rmi -f
      echo "[*] Done"

  else
      echo "Invalid choice. Exiting..."
      exit 1
      
  fi
done

# Check if port is in use and find an available port if necessary
while lsof -ti:$PORT > /dev/null; do
    echo "Port $PORT is in use. Exitting..."
    exit 1
done
echo "Using port $PORT."

# make .env if not available
if [ ! -e "environment/.cred" ]; then
  read -rp "Enter IBKR Username: " tws_userid
  read -rp "Enter IBKR Password: " tws_password
  read -rp "Enter ALPACA_API_KEY: " alpaca_api_key
  read -rp "Enter ALPACA_API_SECRET: " alpaca_api_secret

  echo "ALPACA_API_KEY=$alpaca_api_key" >> environment/.cred
  echo "ALPACA_API_SECRET=$alpaca_api_secret" >> environment/.cred
  echo "TWS_USERID=$tws_userid" >> environment/.cred
  echo "TWS_PASSWORD=$tws_password" >> environment/.cred
fi

if [ ! -e "environment/.pref" ]; then
  read -rp "Enter Lumibot Strategy GitHub URL: " bot_repo
  echo "bot_repo="$bot_repo"" >> environment/.pref
  #bot_repo="git@github.com:Lumiwealth-Strategies/options_condor_martingale.git"

  echo 'ALPACA_BASE_URL="https://paper-api.alpaca.markets/v2"' >> environment/.pref
  echo 'BROKER=IBKR' >> environment/.pref
  echo "INTERACTIVE_BROKERS_IP=ib-gateway" >> environment/.pref
fi

printf "INTERACTIVE_BROKERS_CLIENT_ID=%s\n" "$((RANDOM % 1000 + 1))" >> .env
printf "INTERACTIVE_BROKERS_PORT=%s\n" "$PORT" >> .env

# add variables to local .env
cat "$dir/environment/.cred" >> .env
cat "$dir/environment/.pref" >> .env

# load env variables
source "$dir/.env"

if ! sudo docker images --format "{{.Repository}}" | grep "strategy" > /dev/null 2>&1; then
  git clone "$bot_repo" "$dir/environment/bot" || { echo "Probably not logged into git. Exiting..."; exit 1; }

  # add needed files
  cp environment/requirements.txt environment/bot/
  cp environment/Dockerfile environment/bot/
  cp environment/launch.sh environment/bot/
  cp environment/healthcheck.py environment/bot/

  # patch credentials and pick config
  case $OS in
    'Linux')
      sed -i 's/broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG)/broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG, max_connection_retries=50)/' environment/bot/credentials.py
      sed -i 's/if ALPACA_CONFIG\["API_KEY"\]:/if ALPACA_CONFIG["API_KEY"] and os.environ.get("BROKER", "").lower() == "alpaca":/' environment/bot/credentials.py
      sed -i "s/LIVE_TRADING_CONFIGURATION_FILE_NAME = '.*'/LIVE_TRADING_CONFIGURATION_FILE_NAME = '${selected_config}'/" environment/bot/main.py
      ;;

    'Darwin') 
      sed -i '' 's/broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG)/broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG, max_connection_retries=50)/' environment/bot/credentials.py
      sed -i '' 's/if ALPACA_CONFIG\["API_KEY"\]:/if ALPACA_CONFIG["API_KEY"] and os.environ.get("BROKER", "").lower() == "alpaca":/' environment/bot/credentials.py
      sed -i '' "s/LIVE_TRADING_CONFIGURATION_FILE_NAME = '.*'/LIVE_TRADING_CONFIGURATION_FILE_NAME = '${selected_config}'/" environment/bot/main.py
      ;;

      *) 
      exit 1
      ;;  
  esac
fi

# List available configuration files
echo "Available configuration files:"
config_files=$(ls -1 "environment/bot/configurations")
i=1
for file in $config_files; do
  echo "[$i] $file"
  ((i++))
done

# Prompt user to choose a configuration file
read -rp "Pick a configuration file: " config_choice

# Validate user input
if ! [[ "$config_choice" =~ ^[0-9]+$ ]] || ((config_choice < 1 || config_choice > i-1)); then
  echo "Invalid choice. Exiting..."
  exit 1
fi

# Get the selected configuration file
selected_config="$(basename "$(ls -1 "environment/bot/configurations" | grep ".py$" | sed -n "${config_choice}p")" .py)"

# Set the selected configuration file in .env
echo "CONFIG_FILE=$selected_config" >> .env

# set config
case $OS in
  'Linux')
    sed -i "s/LIVE_TRADING_CONFIGURATION_FILE_NAME = '.*'/LIVE_TRADING_CONFIGURATION_FILE_NAME = '${selected_config}'/" environment/bot/main.py
    ;;

  'Darwin') 
    sed -i '' "s/LIVE_TRADING_CONFIGURATION_FILE_NAME = '.*'/LIVE_TRADING_CONFIGURATION_FILE_NAME = '${selected_config}'/" environment/bot/main.py
    ;;

    *) 
    exit 1
    ;;  
esac

sudo docker compose up --remove-orphans -d