#!/bin/bash

## JQ Json Parser - https://github.com/stedolan/jq
installJq() {
    JQ_CMD=./jq
    JQ_URL=https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
    if [ "$OS" == "Windows_NT" ]; then
      JQ_URL=https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe
    fi
    if [ ! -f ${JQ_CMD} ]; then
      echo " * download jq"
      curl -s -L ${JQ_URL} -o ${JQ_CMD}
    fi
}

installJq