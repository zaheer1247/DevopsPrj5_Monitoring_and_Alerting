#!/usr/bin/env python3
"""
Simple Flask application for monitoring workshop
Demonstrates metrics collection, logging, and error simulation
"""

import os
import time
import random
import logging
from datetime import datetime
from flask import Flask, jsonify, request
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
import json

# Configure logging to console and file under /var/log/flask-app
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Add a FileHandler so Filebeat can ship logs from /var/log/flask-app/app.log
def configure_file_logging(log_file_path: str) -> None:
    root_logger = logging.getLogger()

    # Avoid adding duplicate file handlers on reloads
    for existing_handler in root_logger.handlers:
        if isinstance(existing_handler, logging.FileHandler):
            try:
                if getattr(existing_handler, 'baseFilename', None) == log_file_path:
                    return
            except Exception:
                # If a handler does not have baseFilename, skip it
                pass

    os.makedirs(os.path.dirname(log_file_path), exist_ok=True)
    file_handler = logging.FileHandler(log_file_path)
    file_handler.setLevel(logging.INFO)
    file_handler.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))
    root_logger.addHandler(file_handler)


configure_file_logging('/var/log/flask-app/app.log')
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration')
ACTIVE_CONNECTIONS = Gauge('active_connections', 'Number of active connections')
ERROR_RATE = Gauge('error_rate', 'Current error rate percentage')

# Application state
active_connections = 0
error_count = 0
total_requests = 0

@app.before_request
def before_request():
    global active_connections
    active_connections += 1
    ACTIVE_CONNECTIONS.set(active_connections)

@app.after_request
def after_request(response):
    global active_connections, error_count, total_requests
    active_connections -= 1
    ACTIVE_CONNECTIONS.set(active_connections)
    
    # Update metrics
    total_requests += 1
    if response.status_code >= 400:
        error_count += 1
    
    error_rate = (error_count / total_requests) * 100 if total_requests > 0 else 0
    ERROR_RATE.set(error_rate)
    
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.endpoint or 'unknown',
        status=response.status_code
    ).inc()
    
    return response

@app.route('/')
def home():
    """Home endpoint"""
    logger.info("Home endpoint accessed")
    return jsonify({
        'message': 'Flask Monitoring Workshop App',
        'timestamp': datetime.now().isoformat(),
        'version': '1.0.0'
    })

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/may-fail')
def may_fail():
    """Endpoint that may fail based on configuration"""
    failure_rate = float(os.getenv('FAILURE_RATE', '0.1'))
    
    # Simulate processing time
    time.sleep(random.uniform(0.1, 0.5))
    
    if random.random() < failure_rate:
        logger.error("Simulated error in may-fail endpoint")
        return jsonify({
            'error': 'Simulated failure',
            'timestamp': datetime.now().isoformat()
        }), 500
    
    logger.info("may-fail endpoint succeeded")
    return jsonify({
        'message': 'Success!',
        'timestamp': datetime.now().isoformat(),
        'failure_rate': failure_rate
    })

@app.route('/slow')
def slow():
    """Endpoint that simulates slow responses"""
    delay = float(os.getenv('SLOW_DELAY', '2.0'))
    time.sleep(delay)
    
    logger.info(f"Slow endpoint completed after {delay}s")
    return jsonify({
        'message': f'Slow response after {delay}s',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/status')
def status():
    """Application status endpoint"""
    return jsonify({
        'active_connections': active_connections,
        'total_requests': total_requests,
        'error_count': error_count,
        'error_rate': (error_count / total_requests) * 100 if total_requests > 0 else 0,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/generate-logs')
def generate_logs():
    """Generate various log levels for testing"""
    logger.debug("This is a debug message")
    logger.info("This is an info message")
    logger.warning("This is a warning message")
    logger.error("This is an error message")
    logger.critical("This is a critical message")
    
    return jsonify({
        'message': 'Generated logs at various levels',
        'timestamp': datetime.now().isoformat()
    })

# Fun route that returns a random joke
@app.route('/random-joke')
def random_joke():
    jokes = [
        "Why do programmers prefer dark mode? Because light attracts bugs!",
        "Why do Java developers wear glasses? Because they don't C#!",
        "How many programmers does it take to change a light bulb? None, it's a hardware problem!",
        "I told my computer I needed a break, and it said 'No problem, I'll go to sleep.'",
        "Why was the developer unhappy at their job? They wanted arrays!"
    ]
    joke = random.choice(jokes)
    logger.info("Random joke delivered")
    return jsonify({
        'joke': joke,
        'timestamp': datetime.now().isoformat()
    })


# Simulate user login with simple validation
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    username = data.get('username')
    password = data.get('password')
    
    if not username or not password:
        logger.warning("Login attempt with missing username or password")
        return jsonify({'error': 'Username and password required'}), 400
    
    # This is just a demo, so accept any username/password where password is 'password123'
    if password == 'password123':
        logger.info(f"User {username} logged in successfully")
        return jsonify({'message': f'Welcome, {username}!'})
    else:
        logger.warning(f"Failed login attempt for user {username}")
        return jsonify({'error': 'Invalid credentials'}), 401


# Route to generate random user statistics
@app.route('/user-stats')
def user_stats():
    stats = {
        'users_online': random.randint(1, 100),
        'new_signups': random.randint(0, 20),
        'errors_logged': error_count,
        'server_load': round(random.uniform(0.1, 2.5), 2)
    }
    logger.info("User stats generated")
    return jsonify({
        'statistics': stats,
        'timestamp': datetime.now().isoformat()
    })


# Route that returns a playful error randomly
@app.route('/sometimes-broken')
def sometimes_broken():
    if random.random() < 0.3:
        logger.error("Playful random error at sometimes-broken")
        return jsonify({'error': 'Oops! Something went wrong here. Try again.'}), 500
    else:
        logger.info("sometimes-broken endpoint successful")
        return jsonify({'message': 'All systems go!'} )


# Route that returns current server environment variables (filtered)
@app.route('/env')
def env():
    allowed_vars = ['PATH', 'HOME', 'SHELL', 'USER', 'PORT']
    env_vars = {key: os.getenv(key) for key in allowed_vars if os.getenv(key) is not None}
    logger.info("Environment variables fetched")
    return jsonify({
        'environment': env_vars,
        'timestamp': datetime.now().isoformat()
    })


    # Playful dynamic greeting with emoji based on time
@app.route('/greet')
def greet():
    name = request.args.get('name', 'Friend')
    hour = datetime.now().hour

    if 5 <= hour < 12:
        greeting = 'Rise and shine ☀️ Good morning'
    elif 12 <= hour < 18:
        greeting = 'Hope you\'re having a lovely afternoon 🌻 Good afternoon'
    elif 18 <= hour < 22:
        greeting = 'Relax and unwind 🌙 Good evening'
    else:
        greeting = 'Night owl spotted! 🦉 Good night'

    message = f"{greeting}, {name}!"
    logger.info(f"Greeting sent: {message}")
    return jsonify({'message': message, 'timestamp': datetime.now().isoformat()})


@app.route('/fortune')
def fortune():
    fortunes = [
        "Today is a great day to try something new! 🌟",
        "Good news will come to you by mail. 📬",
        "You will conquer coding bugs with ease today! 🐞",
        "Expect a pleasant surprise before the day's end! 🎁",
        "Avoid unnecessary risks today, stay safe! 🚦"
    ]
    fortune = random.choice(fortunes)
    message = f"Your fortune: {fortune}"
    logger.info(f"Fortune given: {message}")
    return jsonify({'message': message, 'timestamp': datetime.now().isoformat()})


# Random dance move generator for fun breaks
@app.route('/dance-move')
def dance_move():
    moves = [
        "Moonwalk 🌙",
        "Robot 🤖",
        "The Floss 🦷",
        "Jazz Hands ✋",
        "Salsa 💃",
        "Shimmy 🤸‍♂️",
        "Breakdance 🕺",
    ]
    move = random.choice(moves)
    message = f"Time to bust a move: {move}! 💃🕺"
    logger.info(f"Dance move suggested: {message}")
    return jsonify({'message': message, 'timestamp': datetime.now().isoformat()})

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('DEBUG', 'false').lower() == 'true'
    
    logger.info(f"Starting Flask app on port {port}")
    app.run(host='0.0.0.0', port=port, debug=debug)