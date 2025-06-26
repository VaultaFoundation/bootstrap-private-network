#!/usr/bin/env bash

ENDPOINT=$1
WALLET_DIR=$2

# Make sure wallet is open 
"$SCRIPT_DIR"/open_wallet.sh "$WALLET_DIR" root

# needed for powerup
cleos --url $ENDPOINT system buyram eosio eosio.reserv "5 EOS"

# future by 300 seconds 
TARGET=$(date -d "300 seconds" +%FT%T.%3N)
powerup_config="
{
    \"net\": {
        \"assumed_stake_weight\": 99000000000000,
        \"current_weight_ratio\": 10000000000000,
        \"decay_secs\": 86400,
        \"exponent\": 2,
        \"max_price\": \"150000.0000 EOS\",
        \"min_price\": \"1000.0000 EOS\",
        \"target_timestamp\": \"${TARGET}\",
        \"target_weight_ratio\": 10000000000000
    },
    \"cpu\": {
        \"assumed_stake_weight\": 99000000000000,
        \"current_weight_ratio\": 99000000000000,
        \"decay_secs\": 86400,
        \"exponent\": 2,
        \"max_price\": \"75000.0000 EOS\",
        \"min_price\": \"2500.0000 EOS\",
        \"target_timestamp\": \"${TARGET}\",
        \"target_weight_ratio\": 10000000000000
    },
    \"min_powerup_fee\": \"0.1000 EOS\",
    \"powerup_days\": 1
}"

cleos push action eosio cfgpowerup "[${powerup_config}]" -p eosio
# cleos push action eosio powerup '[testuser.2, testuser.2, 1, 30000000000, 30000000000, "1.0000 EOS"]' -p testuser.2
