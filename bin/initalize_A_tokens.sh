#!/usr/bin/env bash

####################
# Creates the core.vaulta user, sets the permissions
# Applys the vaulta contracts
# Initializes the 
#####################

ENDPOINT_ONE=$1
VAULTA_CONTRACT_DIR=$2
WALLET_DIR=$3
SCRIPT_DIR=$4

# Make sure wallet is open 
"$SCRIPT_DIR"/open_wallet.sh "$WALLET_DIR"

# Fund vaulta and add ram
cleos --url $ENDPOINT_ONE transfer eosio vaulta "1000 EOS" "init funding"
cleos --url $ENDPOINT_ONE system buyram eosio vaulta "100 EOS"

# create the keys
[ ! -s "${WALLET_DIR}"/core.vaulta.keys ] && cleos create key --to-console > "${WALLET_DIR}"/core.vaulta.keys
VAULTA_PUBLIC_KEY=$(grep Public "${WALLET_DIR}"/core.vaulta.keys | head -1 | cut -d: -f2 | sed 's/ //g')
VAULTA_PRIVATE_KEY=$(grep Private "${WALLET_DIR}"/core.vaulta.keys | head -1 | cut -d: -f2 | sed 's/ //g')

# Import Core.Vaulta Private Key
cleos wallet import --name finality-test-network-wallet --private-key $VAULTA_PRIVATE_KEY
# Create User
cleos -u $ENDPOINT_ONE system newaccount vaulta core.vaulta ${VAULTA_PUBLIC_KEY} ${VAULTA_PUBLIC_KEY} --stake-net "100.0 EOS" --stake-cpu "100.0 EOS" --buy-ram-kbytes 1000 -pvaulta@active

# set code priviledges  
cleos -u $ENDPOINT_ONE set account permission core.vaulta active --add-code -pcore.vaulta@active

# EOSIO permission  
cleos -u $ENDPOINT_ONE push action eosio setpriv '["core.vaulta", 1]' -p eosio@active

# SET NEW ABI and SET NEW CODE for Wrapper Contracts and swapto
# https://github.com/VaultaFoundation/vaulta-system-contract
cleos -u $ENDPOINT_ONE set contract core.vaulta ${VAULTA_CONTRACT_DIR} system.wasm system.abi -p core.vaulta@active

# Initalize to same amount of EOS 
cleos -u $ENDPOINT_ONE push action core.vaulta init '["2100000000.0000 A"]' -p core.vaulta@active
