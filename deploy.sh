#!/usr/bin/env bash

main(){
  set -e

  dir="$(realpath "$(dirname "$0")")"
  OS="$(uname)"
  cd "$dir"

  cleanup

  # Check Settings
  while [ ! -f "environment/.cred" ] || [ ! -f "environment/.pref" ]; do
    echo "[*] Running setup.sh..."
    source setup.sh
  done

  # create the docker-compose file
  initDockerCompose

  # add all strategies to an array
  while IFS= read -r line; do
      strategies+=("$line")
  done < "environment/.pref"

  # add the strategies to the docker-compose file
  for strategy in "${strategies[@]}"; do
    IFS=',' read -r strategy_name live_or_paper bot_repo db_str config_file webhook ib_subaccount <<< "$strategy"
    trading_mode+="$(addStrategy "$strategy_name" "$live_or_paper" "$bot_repo" "$db_str" "$config_file" "$webhook" "$ib_subaccount")"
  done

  # decide which mode to run the gateway in
  if [[ "$trading_mode" =~ live ]] && [[ "$trading_mode" =~ paper ]]; then
    trading_mode="both"
  elif [[ "$trading_mode" =~ live ]]; then
    trading_mode="live"
  elif [[ "$trading_mode" =~ paper ]]; then
    trading_mode="paper"
  fi

  # add the gateway to the docker-compose
  source environment/.cred
  setupGateway "$trading_mode" "$TWS_USERNAME" "$TWS_PASSWORD"

  # Kill gateways running
  sudo docker ps --format "{{.Names}}" | grep 'ib-gateway' | xargs -r sudo docker kill > /dev/null

  # Run
  sudo docker compose up --remove-orphans -d
}

initDockerCompose(){
  echo "networks: 
  ib_network: 
    driver: bridge

services:" >> docker-compose.yaml
}
# cleanup
cleanup() {
    echo "Performing cleanup..."
    rm -rf "environment/bots"
    rm -f "docker-compose.yaml"
}

setupGateway(){
  local trading_mode="$1"
  local ib_username="$2"
  local ib_password="$3"

  echo "  ib-gateway:
    image: ghcr.io/gnzsnz/ib-gateway:stable
    restart: always
    env_file: 
      - .env
    environment:
      TWS_USERID: $ib_username
      TWS_PASSWORD: $ib_password
      TRADING_MODE: $trading_mode
      TWS_ACCEPT_INCOMING: 'accept'
      VNC_SERVER_PASSWORD: '12345678'
      READ_ONLY_API: 'no'
      TWOFA_TIMEOUT_ACTION: 'restart'
      BYPASS_WARNING: 'yes'
      AUTO_RESTART_TIME: '11:59 PM'
      TWS_COLD_RESTART: '11:59 PM'
      RELOGIN_AFTER_TWOFA_TIMEOUT: 'yes'
      TIME_ZONE: America/New_York
    networks:
      - ib_network
    ports:
      - 5900:5900
  " >> docker-compose.yaml
}

addStrategy(){
  local strategy_name="$1"
  local live_or_paper="$2"
  local bot_repo="$3"
  local db_str="$4"
  local config_file="$5"
  local webhook_url="$6"
  local subaccount="$7"

  if [ "$live_or_paper" == "live" ]; then
    PORT=4003
  elif [ "$live_or_paper" == "paper" ]; then
    PORT=4004
  else
    echo "[*] Bad Trading Mode. Exiting..."
    exit 1
  fi

  # kill existing iterations
  sudo docker ps --format "{{.Names}}" | grep "$strategy_name" | xargs -r sudo docker kill > /dev/null
  sudo docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | grep "$strategy_name" | awk '{print $2}' | xargs -r sudo docker rmi --force

  mkdir -p "environment/bots/$strategy_name"
  git clone "$bot_repo" "environment/bots/$strategy_name" || { echo "Probably not logged into git. Exiting..."; exit 1; }

  # add needed files
  #cp environment/requirements.txt environment/bot/
  cp environment/Dockerfile "environment/bots/$strategy_name"

  # Set config
  if [ -n "$config_file" ]; then 
    case $OS in
      'Linux')
        #sed -i 's/if ALPACA_CONFIG\["API_KEY"\]:/if ALPACA_CONFIG["API_KEY"] and os.environ.get("BROKER", "").lower() == "alpaca":/' environment/bot/credentials.py
        sed -i "s/LIVE_TRADING_CONFIGURATION_FILE_NAME = '.*'/LIVE_TRADING_CONFIGURATION_FILE_NAME = '${config_file}'/" "environment/bots/$strategy_name/main.py"
        ;;

      'Darwin') 
        #sed -i '' 's/if ALPACA_CONFIG\["API_KEY"\]:/if ALPACA_CONFIG["API_KEY"] and os.environ.get("BROKER", "").lower() == "alpaca":/' environment/bot/credentials.py
        sed -i '' "s/LIVE_TRADING_CONFIGURATION_FILE_NAME = '.*'/LIVE_TRADING_CONFIGURATION_FILE_NAME = '${config_file}'/" "environment/bots/$strategy_name/main.py"
        ;;

        *) 
        exit 1
        ;;  
    esac
  fi

  echo "  $strategy_name:
    build:
      context: ./environment/bots/$strategy_name
    env_file: 
      - .env
    restart: always
    depends_on:
      - ib-gateway
    environment:
      INTERACTIVE_BROKERS_PORT: $PORT
      INTERACTIVE_BROKERS_CLIENT_ID: $((RANDOM % 1000 + 1))
      INTERACTIVE_BROKERS_IP: ib-gateway
      DB_CONNECTION_STR: $db_str
      DISCORD_WEBHOOK_URL: $webhook_url
      IB_SUBACCOUNT: $subaccount
    networks: 
      - ib_network
  " >> docker-compose.yaml

  echo "$live_or_paper"
}

main