#!/usr/bin/env bash

USER_NAME=${1}
USER_PUBLIC_KEY=${2}

UTIL_SCRIPT_DIR=/local/VaultaFoundation/repos/bootstrap-private-network/bin

"${UTIL_SCRIPT_DIR}"/open_wallet.sh "${HOME}"/eosio-wallet admin
cleos --url http://127.0.0.1:8888 system newaccount admin.vaulta ${USER_NAME:?} ${USER_PUBLIC_KEY:?} --stake-net "50 EOS" --stake-cpu "50 EOS" --buy-ram "1 EOS" -p admin.vaulta
