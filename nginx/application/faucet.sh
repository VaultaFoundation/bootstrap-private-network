#!/usr/bin/env bash

USER_NAME=${1}

UTIL_SCRIPT_DIR=/local/VaultaFoundation/repos/bootstrap-private-network/bin

"${UTIL_SCRIPT_DIR}"/open_wallet.sh "${HOME}"/eosio-wallet admin
cleos --url http://127.0.0.1:8888 push action eosio.token transfer \
  "{\"to\":\"${USER_NAME}\",\"from\":\"spout.vaulta\",\"quantity\":\"100.0000 EOS\",\"memo\":\"faucet EOS testnet\"}" \
  -pspout.vaulta
cleos --url http://127.0.0.1:8888 push action core.vaulta transfer \
  "{\"to\":\"${USER_NAME}\",\"from\":\"spout.vaulta\",\"quantity\":\"100.0000 A\",\"memo\":\"faucet EOS testnet\"}" \
  -pspout.vaulta