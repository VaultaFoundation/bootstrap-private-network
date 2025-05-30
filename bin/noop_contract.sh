#!/usr/bin/env bash

ENDPOINT_ONE=$1
WALLET_DIR=$2
SCRIPT_DIR=$3

cleos --url $ENDPOINT_ONE transfer eosio enf "10000 EOS" "init funding"
cleos --url $ENDPOINT_ONE system buyram eosio enf "1000 EOS"


[ ! -s "$WALLET_DIR/null.vaulta.keys" ] && cleos create key --to-console > "$WALLET_DIR/null.vaulta.keys"
# head because we want the first match; they may be multiple keys
PRIVATE_KEY=$(grep Private "$WALLET_DIR/null.vaulta.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
PUBLIC_KEY=$(grep Public "$WALLET_DIR/null.vaulta.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
cleos wallet import --name finality-test-network-wallet --private-key $PRIVATE_KEY

cleos --url $ENDPOINT_ONE system newaccount eosio ${producer_name:?} ${PUBLIC_KEY:?} --stake-net "50 EOS" --stake-cpu "500 EOS" --buy-ram "1000 EOS"
# get some spending money
cleos --url $ENDPOINT_ONE transfer eosio null.vaulta "10000 EOS" "init funding"
# self stake some net and cpu
cleos --url $ENDPOINT_ONE system delegatebw null.vaulta null.vaulta "4000.0 EOS" "4000.0 EOS"
# create the contract 
LOCAL_CONTRACTS="${SCRIPT_DIR}"/../contracts
cleos --url $ENDPOINT_ONE set contract null.vaulta "${LOCAL_CONTRACTS}"/noopcontract/ noopcontract.wasm noopcontract.abi
