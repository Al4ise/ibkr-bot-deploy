# Use an official Python runtime as a parent image
FROM python:3.10-slim-bookworm

# Set the working directory in the container to /app
WORKDIR /app

# Add the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
#RUN pip install --no-cache-dir yfinance alpaca-py ccxt ibapi polygon-api-client pandas_ta python_dotenv lumiwealth-tradier pyarrow plotly
#RUN pip install --no-cache-dir lumibot

# Run main.py when the container launches
CMD ["python", "main.py"]
