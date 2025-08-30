#!/usr/bin/env bash

WALLET_DIR=${HOME}/eosio-wallet
BUILD_TEST_DIR=/local/VaultaFoundation/spring_build/tests
SCRIPT_DIR=/local/VaultaFoundation/repos/bootstrap-private-network/bin
TRX_LOG_DIR=/bigata1/log/trx_sync_generator

HTTP_URL=${1:-http://127.0.0.1:5888}
P2P_HOST=${2:-127.0.0.1}
if [ -z $HTTP_URL ] || [ -z $P2P_HOST ]; then
  echo "must supply two arguments the HTTP URL and the P2P Host"
  exit 127
fi
PEER2PEERPORT=${3:-3444}
GENERATORID=0

[ ! -d $TRX_LOG_DIR ] && mkdir $TRX_LOG_DIR

CHAIN_ID=$(cleos --url $HTTP_URL get info | grep chain_id | cut -d:  -f2 | sed 's/[ ",]//g')
LIB_ID=$(cleos --url $HTTP_URL get info | grep last_irreversible_block_id | cut -d:  -f2 | sed 's/[ ",]//g')
sleep 3
${BUILD_TEST_DIR}/trx_generator/trx_generator --generator-id $GENERATORID \
     --chain-id $CHAIN_ID \
     --target-tps 1000 \
     --contract-owner-account caller \
     --actions-data /home/enfuser/basic-test-action.json \
     --abi-file /home/enfuser/sync_caller.abi \
     --actions-auths /home/enfuser/actions-auth.json \
     --last-irreversible-block-id $LIB_ID \
     --log-dir $TRX_LOG_DIR \
     --peer-endpoint-type p2p \
     --peer-endpoint $P2P_HOST \
     --port $PEER2PEERPORT


CHAIN_ID=$(cleos --url $HTTP_URL get info | grep chain_id | cut -d:  -f2 | sed 's/[ ",]//g')
LIB_ID=$(cleos --url $HTTP_URL get info | grep last_irreversible_block_id | cut -d:  -f2 | sed 's/[ ",]//g')
sleep 3
${BUILD_TEST_DIR}/trx_generator/trx_generator --generator-id $GENERATORID \
     --chain-id $CHAIN_ID \
     --target-tps 1000 \
     --contract-owner-account caller \
     --actions-data /home/enfuser/insertperson-test-action.json \
     --abi-file /home/enfuser/sync_caller.abi \
     --actions-auths /home/enfuser/actions-auth.json \
     --last-irreversible-block-id $LIB_ID \
     --log-dir $TRX_LOG_DIR \
     --peer-endpoint-type p2p \
     --peer-endpoint $P2P_HOST \
     --port $PEER2PEERPORT
     