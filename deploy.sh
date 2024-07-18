#!/usr/bin/env bash
set -e

dir="$(realpath "$(dirname "$0")")"
OS="$(uname)"

# cleanup
cleanup() {
    echo "Performing cleanup..."
    rm -rf "$dir/environment/bot"
    rm -f "$dir/.env"
}

# Set up exit trap
cleanup

# .env setup
cd "$dir"

# Add variables to local .env
if [ ! -f "$dir/environment/.cred" ] || [ ! -f "$dir/environment/.pref" ]; then
  echo "[*] Run setup.sh first"
  exit 1
fi

cat "$dir/environment/.cred" >> .env
cat "$dir/environment/.pref" >> .env

# load env variables
source "$dir/.env"

# free ports
# Kill and delete containers
sudo docker ps --format "{{.Names}}" | grep 'strategy' | xargs -r sudo docker kill > /dev/null
sudo docker ps --format "{{.Names}}" | grep 'ib-gateway' | xargs -r sudo docker kill > /dev/null

sudo docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | grep 'strategy' | awk '{print $2}' | xargs -r sudo docker rmi --force

# Check if port is in use and find an available port if necessary
while lsof -ti:$INTERACTIVE_BROKERS_PORT > /dev/null; do
    echo "Port $INTERACTIVE_BROKERS_PORT is in use. Exitting..."
    exit 1
done
echo "Using port $INTERACTIVE_BROKERS_PORT."

printf "INTERACTIVE_BROKERS_CLIENT_ID=%s\n" "$((RANDOM % 1000 + 1))" >> .env

git clone "$bot_repo" "$dir/environment/bot" || { echo "Probably not logged into git. Exiting..."; exit 1; }

# add needed files
#cp environment/requirements.txt environment/bot/
cp environment/Dockerfile environment/bot/
cp environment/launch.sh environment/bot/
cp environment/healthcheck.py environment/bot/

# Set config
if [ -n "$CONFIG_FILE" ]; then 
  case $OS in
    'Linux')
      sed -i "s/LIVE_TRADING_CONFIGURATION_FILE_NAME = '.*'/LIVE_TRADING_CONFIGURATION_FILE_NAME = '${CONFIG_FILE}'/" environment/bot/main.py
      ;;

    'Darwin') 
      sed -i '' "s/LIVE_TRADING_CONFIGURATION_FILE_NAME = '.*'/LIVE_TRADING_CONFIGURATION_FILE_NAME = '${CONFIG_FILE}'/" environment/bot/main.py
      ;;

      *) 
      exit 1
      ;;  
  esac
fi

sudo docker compose up --remove-orphans -d