import os, random
from ib_insync import IB, util, Forex

if __name__ == "__main__":

    if 'IB_GATEWAY_PING_CLIENT_ID' in os.environ:
        clientId = int(os.environ['IB_GATEWAY_PING_CLIENT_ID'])
    else:
        clientId = int(random.random() * 15359) + 1024
    ib = IB()
    # ib.connect('localhost', int(os.environ['IBGW_PORT']), clientId)
    ib.connect('ib-gateway', 8888, clientId)
    contract = Forex('EURUSD')
    bars = ib.reqHistoricalData(
        contract, endDateTime='', durationStr='5 D',
        barSizeSetting='1 day', whatToShow='MIDPOINT', useRTH=True)
    print(bars[-1])