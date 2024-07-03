#!/usr/bin/env bash
set -e

dir="$(realpath "$(dirname "$0")")"

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
bot_repo="git@github.com:Lumiwealth-Strategies/options_condor_martingale.git"
#bot_repo="git@github.com:Lumiwealth-Strategies/options_butterfly_condor.git"
bot_name="$(basename "$bot_repo" .git)"

# free ports
sudo docker ps --format "{{.Names}}" | grep 'strategy' | xargs -r sudo docker kill > /dev/null
sudo docker ps --format "{{.Names}}" | grep 'ib-gateway' | xargs -r sudo docker kill > /dev/null

# reset .env if any
rm -f "$dir/.env"

while [ "$choice" != "1" ] && [ "$choice" != "2" ]; do
  echo "Menu:"
  echo "[1] Trade Live"
  echo "[2] Trade Paper"
  echo "[3] Reset Credentials"
  echo "[4] Docker Prune Everything"
  echo "[5] Docker Prune Strategies"
  echo "[6] Containerize"
  
  read -rp "Enter your choice: " choice

  if [ "$choice" == "1" ]; then
      echo "[*] Will Deploy Live"
      printf "TRADING_MODE=live\n" >> .env
      PORT=4003

  elif [ "$choice" == "2" ]; then
      echo "[*] Will Deploy Paper"
      printf "TRADING_MODE=paper\n" >> .env
      PORT=4004

  elif [ "$choice" == "3" ]; then
      rm -f "environment/.env"
      echo "[*] Credentials Reset"

  elif [ "$choice" == "4" ]; then
    sudo docker system prune -a -f --volumes
    echo "[*] Done"

  elif [ "$choice" == "5" ]; then
    sudo docker images --format "{{.Repository}}" | grep "strategy" | xargs -r sudo docker rmi -f
    echo "[*] Done"


  elif [ "$choice" == "6" ]; then
    #containerize=1
    echo "[*] Will Containerize. It may use more memory,"

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
if [ ! -e "environment/.env" ]; then
  read -rp "Enter TWS_USERID: " tws_userid
  read -rp "Enter TWS_PASSWORD: " tws_password
  read -rp "Enter ALPACA_API_KEY: " alpaca_api_key
  read -rp "Enter ALPACA_API_SECRET: " alpaca_api_secret
  echo "ALPACA_API_KEY=$alpaca_api_key" >> environment/.env
  echo "ALPACA_API_SECRET=$alpaca_api_secret" >> environment/.env
  echo "TWS_USERID=$tws_userid" >> environment/.env
  echo "TWS_PASSWORD=$tws_password" >> environment/.env

  echo 'ALPACA_BASE_URL="https://paper-api.alpaca.markets/v2"' >> environment/.env
  echo 'BROKER=IBKR' >> environment/.env
fi

printf "INTERACTIVE_BROKERS_CLIENT_ID=%s\n" "$((RANDOM % 1000 + 1))" >> .env
printf "INTERACTIVE_BROKERS_PORT=%s\n" "$PORT" >> .env

# add secrets from .env to local .env
cat "$dir/environment/.env" >> .env

printf "INTERACTIVE_BROKERS_IP=ib-gateway\n" >> .env

if ! sudo docker images --format "{{.Repository}}" | grep "strategy" > /dev/null 2>&1; then
  git clone "$bot_repo" "$dir/environment/bot" || { echo "Probably not logged into git. Exiting..."; exit 1; }

  # add needed files
  cp environment/requirements.txt environment/bot/
  cp environment/Dockerfile environment/bot/
  cp environment/healthcheck.py environment/bot/
  cp environment/launch.sh environment/bot/

  # patch credentials and pick config
  OS="$(uname)"
  case $OS in
    'Linux')
      sed -i 's/broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG)/broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG, max_connection_retries=50)/' environment/bot/credentials.py
      sed -i 's/if ALPACA_CONFIG\["API_KEY"\]:/if ALPACA_CONFIG["API_KEY"] and os.environ.get("BROKER", "").lower() == "alpaca":/' environment/bot/credentials.py
      ;;
    'Darwin') 
      sed -i '' 's/broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG)/broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG, max_connection_retries=50)/' environment/bot/credentials.py
      sed -i '' 's/if ALPACA_CONFIG\["API_KEY"\]:/if ALPACA_CONFIG["API_KEY"] and os.environ.get("BROKER", "").lower() == "alpaca":/' environment/bot/credentials.py
      ;;
    *) 
    exit 1
    ;;  
  esac
fi

sudo docker compose up --remove-orphans -d