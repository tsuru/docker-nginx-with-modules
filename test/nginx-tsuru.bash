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

test_lua_content() {
    response=$(curl --fail --silent --show-error http://localhost:8080/lua_content)
    assert "Hello,world!" "$response" "/lua_content with expected response"
}

test_lua_http_resty() {
    response=$(curl --fail --silent --show-error http://localhost:8080/lua_http_resty)
    assert "Proxyied response: nginx config check ok" "$response" "/lua_http_resty with expected response"
}

echo "Running tests"

test_nginx_serving_request
test_lua_content
test_lua_http_resty

echo "✅ SUCESS: All tests passed"