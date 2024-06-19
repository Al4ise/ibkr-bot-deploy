#!/usr/bin/env bash

dir="$(realpath "$(dirname "$0")")"

# rebuild flag
if [[ "$*" =~ -r ]]; then
  echo "Will Rebuild"
  rm "$dir/environment/options-butterfly-condor.tar"
  rm "$dir/environment/ib-gateway-docker.tar"
  rebuild=1
else
  echo "Won't Rebuild"
fi

if [[ "$*" =~ -v ]]; then
  echo "Verbose On"
  verbose=1
fi

# cleanup
cleanup() {
    echo "Performing cleanup..."
    rm -f "$dir/.env"
    rm -rf "$dir/environment/options_butterfly_condor"
}

# Set up exit trap
cleanup
trap cleanup EXIT SIGINT SIGTERM

# .env setup
cd "$dir"

# make .env if not available
if [ ! -e "environment/.env" ]; then
  read -rp "Enter TWS_USERID: " tws_userid
  read -rp "Enter TWS_PASSWORD: " tws_password
  echo "TWS_USERID=$tws_userid" >> environment/.env
  echo "TWS_PASSWORD=$tws_password" >> environment/.env
fi

# pick trade mode
echo "Select trading mode:"
echo "[1] Live"
echo "[2] Paper"
read -rp "Enter your choice: " choice

if [ "$choice" == "1" ]; then
    echo "[*] Will Deploy Live"
    printf "TRADING_MODE=live\n" >> .env
    PORT=4003


elif [ "$choice" == "2" ]; then
    echo "[*] Will Deploy Paper"
    printf "TRADING_MODE=paper\n" >> .env
    PORT=4004

else
    echo "Invalid choice. Exiting..."
    exit 1
    
fi

# free ports
ib=( $(sudo docker ps -q --filter ancestor=gnzsnz/ib-gateway-docker) )
if [ "${#ib[@]}" -gt 0 ]; then
    sudo docker kill "${ib[@]}" > /dev/null
fi

obc=( $(sudo docker ps -q --filter ancestor=options-butterfly-condor) )
if [ "${#obc[@]}" -gt 0 ]; then
    sudo docker kill "${obc[@]}" > /dev/null
fi

# Check if port is in use and find an available port if necessary
while lsof -ti:$PORT > /dev/null; do
    echo "Port $PORT is in use. Exitting..."
    exit 1
done
echo "Using port $PORT."

cd "$dir"
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

if [ ! -e "$dir/environment/options-butterfly-condor.tar" ] || [ -n "$rebuild" ]; then
# get bot
  cd "$dir/environment"
  git clone "git@github.com:Lumiwealth-Strategies/options_butterfly_condor.git" || { echo "Probably not logged into git. Exiting..."; exit 1; }

  # add needed files
  cp Dockerfile options_butterfly_condor/
  cp requirements.txt options_butterfly_condor/

  # add retries to bot ib connection
  OS="$(uname)"
  case $OS in
    'Linux')
      sed -i 's/broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG)/broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG, max_connection_retries=50)/' "$dir/environment/options_butterfly_condor/credentials.py"
      ;;
    'Darwin') 
      sed -i '' 's/broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG)/broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG, max_connection_retries=50)/' "$dir/environment/options_butterfly_condor/credentials.py"
      ;;
    *) 
    exit 1
    ;;
  esac

  # build options-butterfly-condor
  cd "$dir/environment/options_butterfly_condor"
  sudo docker buildx build -t options-butterfly-condor .
  sudo docker save options-butterfly-condor > "$dir/environment/options-butterfly-condor.tar"
fi

if [ ! -e "$dir/environment/ib-gateway-docker.tar" ] || [ -n "$rebuild" ]; then
  # pull ghcr.io/gnzsnz/ib-gateway-docker
  sudo docker pull ghcr.io/gnzsnz/ib-gateway-docker
  sudo docker save ghcr.io/gnzsnz/ib-gateway-docker > "$dir/environment/ib-gateway-docker.tar"
fi

#sudo docker load < "$dir/environment/ib-gateway-docker.tar"
sudo docker load < "$dir/environment/options-butterfly-condor.tar"
sudo docker load < "$dir/environment/ib-gateway-docker.tar"

# run
if [ -z "$verbose" ]; then
  d="-d"
fi

OS="$(uname)"
case $OS in
  'Linux')
    sudo docker-compose -f docker-compose.yaml up "$d"
    #while ! python healthcheck.py; do sleep 5; done
    #sudo docker-compose -f docker-compose-obc.yaml up "$d"
    ;;

  'Darwin') 
    sudo docker compose -f docker-compose-ib.yaml up "$d"
    #while ! python healthcheck.py; do sleep 5; done
    #sudo docker compose -f docker-compose-obc.yaml up "$d"
    ;;

  *) 
   exit 1
   ;;
esac