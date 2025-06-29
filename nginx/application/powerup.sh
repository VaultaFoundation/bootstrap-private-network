#!/usr/bin/env bash

USER_NAME=${1}

UTIL_SCRIPT_DIR=/local/VaultaFoundation/repos/bootstrap-private-network/bin

"${UTIL_SCRIPT_DIR}"/open_wallet.sh "${HOME}"/eosio-wallet admin
cleos --url http://127.0.0.1:8888 push action eosio powerup \
  "["${USER_NAME}", "${USER_NAME}", 1, 30000000000, 30000000000, \"1.0000 EOS\"]" -p $USER_NAME

  