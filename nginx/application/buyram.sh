#!/usr/bin/env bash

USER_NAME=${1}

UTIL_SCRIPT_DIR=/local/VaultaFoundation/repos/bootstrap-private-network/bin

"${UTIL_SCRIPT_DIR}"/open_wallet.sh "${HOME}"/eosio-wallet admin
cleos --url http://127.0.0.1:8888 system buyram admin.vaulta ${USER_NAME:?} "10 EOS" -p admin.vaulta
