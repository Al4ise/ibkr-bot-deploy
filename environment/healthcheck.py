from lumibot.strategies.strategy import Strategy
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
