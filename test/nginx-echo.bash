#!/bin/bash -e 

assert() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  
  if [[ "$expected" == "$actual" ]]; then
    echo "✅ SUCESS: $message"
  else
    echo "❌ FAIL: $message"
    echo "   ➡ Expected: '$expected', Obtained: '$actual'"
    exit 1
  fi
}

test_nginx_serving_request() {
    response=$(curl --fail --silent --show-error http://localhost:8080/)
    assert "nginx config check ok" "$response" "/ with expected response"
}

echo "Running tests"

test_nginx_serving_request

echo "✅ SUCESS: All tests passed"