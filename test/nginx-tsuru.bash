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
    assert '{"body":"nginx config check ok\n","proxied":true}' "$response" "/lua_http_resty with expected response"
}

test_brotli() {
    response=$(curl --fail --silent --show-error localhost:8080/brotli)
    assert '<b>Brotli page</b>' "$response" "/brotli without compression response"

    response=$(curl --fail --silent --show-error -H 'Accept-Encoding: br' localhost:8080/brotli | base64)
    assert 'BQmAPGI+QnJvdGxpIHBhZ2U8L2I+CgM=' "$response" "/brotli with brotli compression response"
}

test_libjwt_no_token() {
    response=$(curl --silent --show-error http://localhost:8080/libjwt)
    assert '{"message":"token not found"}' "$response" "/libjwt with expected response"
}

test_libjwt_with_token() {
    response=$(curl --fail --silent --show-error http://localhost:8080/libjwt -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6ImtpZC10c3VydSIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZSwiZW1haWwiOiJ0c3VydUB0c3VydS5jb20iLCJleHAiOjIwNTY5OTA3ODEsImlhdCI6MTc0MTYzMDc4MSwibmFtZSI6IlRzdXJ1Iiwic3ViIjoiMTIzNDU2Nzg5MCJ9.osEVAXF1ysV3pwoeOwaPSZK97AzMDMqCD-cyZ4ALHhLatBHszXrPqn6sJxUQdvET_RK0IJyJd15mw-Y1EMZ6WLKBjeV_iWuapQ9-7gh6sQoloZZ0V0ZNfXlbqCGoTXHb-xInFsGEgV6rj4R-5Sl1r96UiYpLdav8GmT3lKrRPILCLvihXFtiuhrUX1rmNhbiKqlIDyAPtG8rjqQzqEDqKkYH2bApjSrgsyevG9do31vbnEljukON-Hc5MgQK7zr4ZF3Ozi4m0JRy3jeIWVzpsWm9dRnTb9mcOfuY5EQP7NhFBXu-H4H-RwvStfZhfN8J9FbOR8jGEEDhUYHsLaRXNQ")
    assert 'OK' "$response" "/libjwt with expected response"
}

echo "Running tests"

test_nginx_serving_request
test_lua_content
test_lua_http_resty
test_brotli
test_libjwt_with_token
test_libjwt_no_token

echo "✅ SUCESS: All tests passed"