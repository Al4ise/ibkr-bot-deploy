# NOTE: 
# This file is not meant to be modified. This file loads the credentials from the ".env" file or secrets and sets them as environment variables.
# If you want to set the environment variables on your computer, you can do so by creating a ".env" file in the root directory of the project
# and adding the variables described in the "Secrets Configuration" section of the README.md file like this (but without the "# " at the front):
# IS_BACKTESTING=True
# POLYGON_API_KEY=p0izKxeskywlLjKi82NLrQPUvSzvlYVT
# etc.

import os
from lumibot.brokers import Alpaca, Ccxt, Tradier, InteractiveBrokers

import dotenv

dotenv.load_dotenv()

# Check if we are backtesting or not
is_backtesting = os.environ.get("IS_BACKTESTING")
if not is_backtesting or is_backtesting.lower() == "false":
    IS_BACKTESTING = False
else:
    IS_BACKTESTING = True

# Discord credentials
DISCORD_WEBHOOK_URL = os.environ.get("DISCORD_WEBHOOK_URL")

# Database connection string
ACCOUNT_HISTORY_DB_CONNECTION_STR = os.environ.get("ACCOUNT_HISTORY_DB_CONNECTION_STR")

# Name for the strategy to be used in the database
STRATEGY_NAME = os.environ.get("STRATEGY_NAME")

POLYGON_CONFIG = {
    # Add POLYGON_API_KEY and POLYGON_IS_PAID_SUBSCRIPTION to your .env file or set them as secrets
    "API_KEY": os.environ.get("POLYGON_API_KEY"),
    "IS_PAID_SUBSCRIPTION": os.environ.get("POLYGON_IS_PAID_SUBSCRIPTION").lower()
    == "true"
    if os.environ.get("POLYGON_IS_PAID_SUBSCRIPTION")
    else False,
}

ALPACA_CONFIG = {  # Paper trading!
    # Add ALPACA_API_KEY, ALPACA_API_SECRET, and ALPACA_IS_PAPER to your .env file or set them as secrets
    "API_KEY": os.environ.get("ALPACA_API_KEY"),
    "API_SECRET": os.environ.get("ALPACA_API_SECRET"),
    "PAPER": os.environ.get("ALPACA_IS_PAPER").lower() == "true"
    if os.environ.get("ALPACA_IS_PAPER")
    else True,
}

TRADIER_CONFIG = {
    # Add TRADIER_ACCESS_TOKEN, TRADIER_ACCOUNT_NUMBER, and TRADIER_IS_PAPER to your .env file or set them as secrets
    "ACCESS_TOKEN": os.environ.get("TRADIER_ACCESS_TOKEN"),
    "ACCOUNT_NUMBER": os.environ.get("TRADIER_ACCOUNT_NUMBER"),
    "PAPER": os.environ.get("TRADIER_IS_PAPER").lower() == "true"
    if os.environ.get("TRADIER_IS_PAPER")
    else True,
}

KRAKEN_CONFIG = {
    # Add KRAKEN_API_KEY and KRAKEN_API_SECRET to your .env file or set them as secrets
    "exchange_id": "kraken",
    "apiKey": os.environ.get("KRAKEN_API_KEY"),
    "secret": os.environ.get("KRAKEN_API_SECRET"),
    "margin": True,
    "sandbox": False,
}

COINBASE_CONFIG = {
    # Add COINBASE_API_KEY and COINBASE_API_SECRET to your .env file or set them as secrets
    "exchange_id": "coinbase",
    "apiKey": os.environ.get("COINBASE_API_KEY"),
    "secret": os.environ.get("COINBASE_API_SECRET"),
    "margin": False,
    "sandbox": False,
}

INTERACTIVE_BROKERS_CONFIG = {
    "SOCKET_PORT": int(os.environ.get("INTERACTIVE_BROKERS_PORT")) if os.environ.get("INTERACTIVE_BROKERS_PORT") else None,
    "CLIENT_ID": int(os.environ.get("INTERACTIVE_BROKERS_CLIENT_ID")) if os.environ.get("INTERACTIVE_BROKERS_CLIENT_ID") else None,
    "IP": os.environ.get("INTERACTIVE_BROKERS_IP", "127.0.0.1"),
}

if IS_BACKTESTING:
    broker = None
else:
    # If using Alpaca as a broker, set that as the broker
    if ALPACA_CONFIG["API_KEY"] and os.environ.get("BROKER", "").lower() == "alpaca":
        broker = Alpaca(ALPACA_CONFIG)

    # If using Tradier as a broker, set that as the broker
    elif TRADIER_CONFIG["ACCESS_TOKEN"]:
        broker = Tradier(TRADIER_CONFIG)

    # If using Coinbase as a broker, set that as the broker
    elif COINBASE_CONFIG["apiKey"]:
        broker = Ccxt(COINBASE_CONFIG)

    # If using Kraken as a broker, set that as the broker
    elif KRAKEN_CONFIG["apiKey"]:
        broker = Ccxt(KRAKEN_CONFIG)

    # If using Interactive Brokers as a broker, set that as the broker
    elif INTERACTIVE_BROKERS_CONFIG["SOCKET_PORT"]:
        broker = InteractiveBrokers(INTERACTIVE_BROKERS_CONFIG, max_connection_retries=50)

    # If no broker is set, raise an error
    else:
        raise ValueError("No broker set! Please set a broker in a .env file or as a secret.")