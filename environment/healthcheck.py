import os
from datetime import datetime, timedelta

import pandas as pd
import pandas_ta as ta
import pytz
from lumibot.entities import Asset, TradingFee
from lumibot.strategies.strategy import Strategy
import yfinance as yf

from credentials import broker

class ConnectionTest(Strategy):
    def initialize(self):
        dt = self.get_datetime()

        if dt is None:
            exit(1)
        exit(0)


strategy = ConnectionTest(
    broker=broker,
    name="ConnectionTest"
    )
