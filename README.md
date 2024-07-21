# Automatic Configuration (Recommended)

Run `setup.sh` and follow the instructions

# Manual Configuration

This document provides details on the configuration options available within the `.pref` and `.cred` files located in the /environment directory of the project.

## `environment/.cred` File

The `.cred` file is used to store sensitive credentials required by the application.

- `TWS_USERID`: Your IBKR Username.
- `TWS_PASSWORD`: Your IBKR Password
- `ALPACA_API_KEY`: The API key for Alpaca. Used for news trading (Optional).
- `ALPACA_API_SECRET`: The secret key for Alpaca API (Optional).

## `environment/.pref` File

The `environment/.pref` file contains user preferences that customize the application's behavior. The specific arguments and their descriptions are as follows:

(Here, you would list the arguments found in the `.pref` file, similar to the `.cred` file documentation above, but since the `.pref` file's contents weren't provided, I'll include placeholder text.)

- `BOT_REPO`: A GitHub link to the bot you will use in SSH format (e.g: git@github.com:organization/repo.git)
- `TRADING_MODE`: 'paper' or 'live'. Paper should be paired with INTERACTIVE_BROKERS_PORT=4004, and live - with INTERACTIVE_BROKERS_PORT=4003
- `INTERACTIVE_BROKERS_PORT`: 4004 or 4003
- `CONFIG_FILE`: Some bots have a 'configurations' directory, containing files that specify the parameters a bot uses. Set CONFIG_FILE to the filename (omit the extension) of the file you wish to use. Or leave blank for the default

- `ALPACA_BASE_URL="https://paper-api.alpaca.markets/v2"`: Necessary Variable
- `BROKER=IBKR`: Necessary Variable
- `INTERACTIVE_BROKERS_IP=ib-gateway`: Necessary Variable

## Example `.cred` File

The following is an example of a `.cred` file:

```
TWS_USERID=my_username
TWS_PASSWORD=my_password
ALPACA_API_KEY=my_alpaca_api_key
ALPACA_API_SECRET=my_alpaca_api_secret
```

## Example `.pref` File

The following is an example of a `.pref` file:

```
BOT_REPO=git@github.com:organization/repo.git
TRADING_MODE=paper
INTERACTIVE_BROKERS_PORT=4004
CONFIG_FILE=my_config_file
ALPACA_BASE_URL="https://paper-api.alpaca.markets/v2"
BROKER=IBKR
INTERACTIVE_BROKERS_IP=ib-gateway
```
