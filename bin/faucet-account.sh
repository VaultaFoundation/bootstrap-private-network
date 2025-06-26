#!/usr/bin/env bash

ENDPOINT_ONE=$1
WALLET_DIR=$2

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
"${SCRIPT_DIR}"/open_wallet.sh "$WALLET_DIR" admin

# create faucet account 
admin_name="spout.vaulta"
[ ! -s "$WALLET_DIR/${admin_name}.keys" ] && cleos create key --to-console > "$WALLET_DIR/${admin_name}.keys"
# head because we want the first match; they may be multiple keys
ADMIN_PRIVATE_KEY=$(grep Private "$WALLET_DIR/${admin_name}.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
ADMIN_PUBLIC_KEY=$(grep Public "$WALLET_DIR/${admin_name}.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
cleos wallet import --name admin-test-network-wallet --private-key $ADMIN_PRIVATE_KEY

cleos --url $ENDPOINT_ONE system newaccount eosio ${admin_name:?} ${ADMIN_PUBLIC_KEY:?} --stake-net "500 EOS" --stake-cpu "5000 EOS" --buy-ram "10000 EOS"
# get some spending money
cleos --url $ENDPOINT_ONE transfer eosio ${admin_name} "200000000 EOS" "faucet funding"
# self stake some net and cpu
cleos --url $ENDPOINT_ONE system delegatebw ${admin_name} ${admin_name} "4000.0 EOS" "4000.0 EOS"
