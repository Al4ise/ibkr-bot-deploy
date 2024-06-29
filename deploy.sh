#!/usr/bin/env bash

dir="$(realpath "$(dirname "$0")")"

# cleanup
cleanup() {
    echo "Performing cleanup..."
    rm -f "$dir/.env"
    rm -rf "$dir/environment/bot"
}

# Set up exit trap
cleanup
trap cleanup EXIT SIGINT SIGTERM

# .env setup
cd "$dir"
PORT=8888
bot_repo="git@github.com:Lumiwealth-Strategies/options_condor_martingale.git"
#bot_repo="git@github.com:Lumiwealth-Strategies/options_butterfly_condor.git"
bot_name="$(basename "$bot_repo" .git)"

while [ "$choice" != "1" ] && [ "$choice" != "2" ]; do
  echo "Menu:"
  echo "[1] Trade Live"
  echo "[2] Trade Paper"
  echo "[3] Reset Credentials"
  echo "[4] Docker Prune Everything"
  
  read -rp "Enter your choice: " choice

  if [ "$choice" == "1" ]; then
      echo "[*] Will Deploy Live"
      printf "TRADING_MODE=live\n" >> .env

  elif [ "$choice" == "2" ]; then
      echo "[*] Will Deploy Paper"
      printf "TRADING_MODE=paper\n" >> .env

  elif [ "$choice" == "3" ]; then
      rm -f "environment/.env"
      echo "[*] Credentials Reset"

  elif [ "$choice" == "4" ]; then
    sudo docker system prune -a -f
    echo "[*] Done"

  else
      echo "Invalid choice. Exiting..."
      exit 1
      
  fi
done

# free ports
sudo docker ps --format "{{.Names}}" | grep "$bot_name" | xargs -r sudo docker kill > /dev/null
sudo docker ps --format "{{.Names}}" | grep 'ib-gateway' | xargs -r sudo docker kill > /dev/null

# Check if port is in use and find an available port if necessary
while lsof -ti:$PORT > /dev/null; do
    echo "Port $PORT is in use. Exitting..."
    exit 1
done
echo "Using port $PORT."

# make .env if not available
if [ ! -e "environment/.env" ]; then
  read -rp "Enter USERNAME: " tws_userid
  read -rp "Enter PASSWORD: " tws_password
  echo "USERNAME=$tws_userid" >> environment/.env
  echo "PASSWORD=$tws_password" >> environment/.env
fi

printf "INTERACTIVE_BROKERS_CLIENT_ID=%s\n" "$((RANDOM % 1000 + 1))" >> .env
printf "INTERACTIVE_BROKERS_PORT=%s\n" "$PORT" >> .env
printf "INTERACTIVE_BROKERS_IP=ib-gateway\n" >> .env
printf "TWOFA_TIMEOUT_ACTION=restart\n" >> .env
printf "AUTO_RESTART_TIME=11:59 PM\n" >> .env
printf "RELOGIN_AFTER_2FA_TIMEOUT=yes\n" >> .env
printf "TIME_ZONE=Europe/Zurich\n" >> .env
printf "TWS_ACCEPT_INCOMING=accept\n" >> .env
printf "BYPASS_WARNING=yes\n" >> .env
printf "VNC_SERVER_PASSWORD=12345678\n" >> .env
printf "READ_ONLY_API=no\n" >> .env

# add secrets from .env to local .env
cat "$dir/environment/.env" >> .env

git clone "$bot_repo" "$dir/environment/bot" || { echo "Probably not logged into git. Exiting..."; exit 1; }

# add needed files
if [ ! -e "$dir/environment/bot/requirements.txt" ]; then 
  cp environment/Dockerfile "$dir/environment/bot/"
fi

cp environment/requirements.txt "$dir/environment/bot/"
cp environment/healthcheck.py "$dir/environment/bot/"
cp environment/launch.sh "$dir/environment/bot/"

# add retries to bot ib connection
OS="$(uname)"
case $OS in
  'Linux')
    sed -i 's/broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG)/broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG, max_connection_retries=50)/' "$dir/environment/bot/credentials.py"
    ;;
  'Darwin') 
    sed -i '' 's/broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG)/broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG, max_connection_retries=50)/' "$dir/environment/bot/credentials.py"
    ;;
  *) 
  exit 1
  ;;  
esac

sudo docker compose up --remove-orphans -d