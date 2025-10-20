#!/bin/bash

BASE_URL="http://localhost:5000"

echo "Testing /"
curl -s "$BASE_URL/"
echo -e "\n"

echo "Testing /health"
curl -s "$BASE_URL/health"
echo -e "\n"

echo "Testing /metrics"
curl -s "$BASE_URL/metrics"
echo -e "\n"

echo "Testing /may-fail"
curl -s "$BASE_URL/may-fail"
echo -e "\n"

echo "Testing /slow"
curl -s "$BASE_URL/slow"
echo -e "\n"

echo "Testing /status"
curl -s "$BASE_URL/status"
echo -e "\n"

echo "Testing /generate-logs"
curl -s "$BASE_URL/generate-logs"
echo -e "\n"

echo "Testing /random-joke"
curl -s "$BASE_URL/random-joke"
echo -e "\n"

echo "Testing /login with valid credentials"
curl -s -X POST -H "Content-Type: application/json" -d '{"username":"testuser","password":"password123"}' "$BASE_URL/login"
echo -e "\n"

echo "Testing /login with invalid credentials"
curl -s -X POST -H "Content-Type: application/json" -d '{"username":"testuser","password":"wrongpass"}' "$BASE_URL/login"
echo -e "\n"

echo "Testing /user-stats"
curl -s "$BASE_URL/user-stats"
echo -e "\n"

echo "Testing /sometimes-broken"
curl -s "$BASE_URL/sometimes-broken"
echo -e "\n"

echo "Testing /env"
curl -s "$BASE_URL/env"
echo -e "\n"

echo "Testing /greet with name parameter"
curl -s "$BASE_URL/greet?name=ChatGPT"
echo -e "\n"

echo "Testing /fortune"
curl -s "$BASE_URL/fortune"
echo -e "\n"

echo "Testing /dance-move"
curl -s "$BASE_URL/dance-move"
echo -e "\n"
