from lumibot.strategies.strategy import Strategy
from credentials import broker

class ConnectionTest(Strategy):
    def initialize(self):
        dt = self.get_datetime()

        if dt is None:
            self.log_message("-------------------------broken")
            exit(1)
        exit(0)

strategy = ConnectionTest(
    broker=broker,
    name="ConnectionTest"
    )
