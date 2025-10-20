# python3 noop_webhook.py > Dummy url for Alertmanager webhook configuration
# http://localhost:8089/noop-webhook

from flask import Flask, request
import logging

app = Flask(__name__)

# Configure logging to a file
logging.basicConfig(filename='noop_webhook.log',
                    level=logging.INFO,
                    format='%(asctime)s - %(message)s')

@app.route('/noop-webhook', methods=['POST'])
def noop_webhook():
    # Log incoming request details
    logging.info(f"Headers: {dict(request.headers)}")
    logging.info(f"Body: {request.get_data(as_text=True)}")
    
    # Respond with HTTP 200 OK
    return '', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
