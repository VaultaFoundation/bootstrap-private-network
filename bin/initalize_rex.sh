#!/usr/bin/env bash

####################
# Creates the rex pool
#####################

ENDPOINT_ONE=$1
WALLET_DIR=$3

# Make sure wallet is open 
"$SCRIPT_DIR"/open_wallet.sh "$WALLET_DIR" root

# Fund vaulta and add ram
cleos --url $ENDPOINT_ONE transfer eosio vaulta "100000000 EOS" "init funding"
cleos --url $ENDPOINT_ONE system buyram eosio vaulta "100 EOS"

cleos --url $ENDPOINT_ONE push action eosio setrexmature '{"num_of_maturity_buckets": 21,"sell_matured_rex": true,"buy_rex_to_savings": true}' -p eosio
cleos --url $ENDPOINT_ONE push action eosio.token transfer '{"to":"core.vaulta","from":"eosio","quantity":"1000000.0000 EOS","memo":"swap to fund rex deposit"}' -p eosio
cleos --url $ENDPOINT_ONE push action core.vaulta deposit '{"owner":"eosio","amount":"1000000.0000 A"}' -p eosio
cleos --url $ENDPOINT_ONE push action eosio buyrex '{"from":"eosio","amount":"1000000.0000 EOS"}' -p eosio
