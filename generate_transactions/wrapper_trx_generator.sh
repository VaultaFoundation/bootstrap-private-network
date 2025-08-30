#!/usr/bin/env bash

WALLET_DIR=${HOME}/eosio-wallet
BUILD_TEST_DIR=/local/VaultaFoundation/spring_build/tests
SCRIPT_DIR=/local/VaultaFoundation/repos/bootstrap-private-network/bin
TRX_LOG_DIR=/bigata1/log/trx_generator

HTTP_URL=${1:-http://127.0.0.1:5888}
P2P_HOST=${2:-127.0.0.1}
if [ -z $HTTP_URL ] || [ -z $P2P_HOST ]; then
  echo "must supply two arguments the HTTP URL and the P2P Host"
  exit 127
fi
PEER2PEERPORT=${3:-3444}
GENERATORID=0
ACCOUNTS=("usera" "userb")
PRIVKEYS=($(grep 'Private key' ~/eosio-wallet/user.keys  | cut -d: -f2) $(grep 'Private key' ~/eosio-wallet/user.keys  | cut -d: -f2))

unset COMMA_SEP_ACCOUNTS
unset COMMA_SEP_KEYS

# open wallet
${SCRIPT_DIR}/open_wallet.sh ${WALLET_DIR} users
for name in "${ACCOUNTS[@]}"; do
  COMMA_SEP_ACCOUNTS+="${name},"
done
COMMA_SEP_ACCOUNTS=${COMMA_SEP_ACCOUNTS%,}

for key in "${PRIVKEYS[@]}"; do
  COMMA_SEP_KEYS+="${key},"
done
COMMA_SEP_KEYS=${COMMA_SEP_KEYS%,}

[ ! -d $TRX_LOG_DIR ] && mkdir $TRX_LOG_DIR

CHAIN_ID=$(cleos --url $HTTP_URL get info | grep chain_id | cut -d:  -f2 | sed 's/[ ",]//g')
LIB_ID=$(cleos --url $HTTP_URL get info | grep last_irreversible_block_id | cut -d:  -f2 | sed 's/[ ",]//g')
sleep 3
${BUILD_TEST_DIR}/trx_generator/trx_generator --generator-id $GENERATORID \
     --chain-id $CHAIN_ID \
     --target-tps 1000 \
     --contract-owner-account core.vaulta \
     --accounts $COMMA_SEP_ACCOUNTS \
     --priv-keys $COMMA_SEP_KEYS \
     --last-irreversible-block-id $LIB_ID \
     --log-dir $TRX_LOG_DIR \
     --peer-endpoint-type p2p \
     --peer-endpoint $P2P_HOST \
     --port $PEER2PEERPORT