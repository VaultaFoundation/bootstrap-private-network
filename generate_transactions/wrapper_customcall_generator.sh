#!/usr/bin/env bash
WALLET_DIR=${HOME}/eosio-wallet
BUILD_TEST_DIR=/local/VaultaFoundation/spring_build/tests
SCRIPT_DIR=/local/VaultaFoundation/repos/bootstrap-private-network/bin
TRX_LOG_DIR=/bigata1/log/trx_sync_generator
ACTION_FILE=$1
TEMPLATE_FILE=$2
SHORT_NAME=$3
HTTP_URL=http://127.0.0.1:5888
P2P_HOST=127.0.0.1
if [ -z $HTTP_URL ] || [ -z $P2P_HOST ]; then
  echo "must supply two arguments the HTTP URL and the P2P Host"
  exit 127
fi
PEER2PEERPORT=${4:-1444}
GENERATORID=0
USERS="userd usere userf userg userh useri userj userk userl userm usern usero userp userq userr users usert"

# Convert USERS string to array
USERS_ARRAY=($USERS)
TOTAL_USERS=${#USERS_ARRAY[@]}

# Get current user index from file, or start at 0
CURRENT_INDEX_FILE="${WALLET_DIR}/CURRENT_USER_INDEX_${SHORT_NAME}.txt"
if [ -f "$CURRENT_INDEX_FILE" ]; then
    CURRENT_INDEX=$(cat "$CURRENT_INDEX_FILE")
    # Validate index is a number and within bounds
    if ! [[ "$CURRENT_INDEX" =~ ^[0-9]+$ ]] || [ "$CURRENT_INDEX" -ge "$TOTAL_USERS" ]; then
        CURRENT_INDEX=0
    fi
else
    CURRENT_INDEX=0
fi

# Get the current user
THIS_USER=${USERS_ARRAY[$CURRENT_INDEX]}

# Calculate next index (wrap around to 0 if at end)
NEXT_INDEX=$(( (CURRENT_INDEX + 1) % TOTAL_USERS ))

# Save next index for next run
echo "$NEXT_INDEX" > "$CURRENT_INDEX_FILE"

sed "s/XXUSERXX/$THIS_USER/g" "${TEMPLATE_FILE}" > "$ACTION_FILE"
echo "Using user: $THIS_USER (index $CURRENT_INDEX)"

[ ! -d $TRX_LOG_DIR ] && mkdir $TRX_LOG_DIR
CHAIN_ID=$(cleos --url $HTTP_URL get info | grep chain_id | cut -d:  -f2 | sed 's/[ ",]//g')
LIB_ID=$(cleos --url $HTTP_URL get info | grep last_irreversible_block_id | cut -d:  -f2 | sed 's/[ ",]//g')
sleep 3
${BUILD_TEST_DIR}/trx_generator/trx_generator --generator-id $GENERATORID \
     --chain-id $CHAIN_ID \
     --target-tps 1000 \
     --contract-owner-account caller \
     --actions-data $ACTION_FILE \
     --abi-file /home/enfuser/sync_caller.abi \
     --actions-auths /home/enfuser/actions-auth.json \
     --last-irreversible-block-id $LIB_ID \
     --log-dir $TRX_LOG_DIR \
     --peer-endpoint-type p2p \
     --peer-endpoint $P2P_HOST \
     --port $PEER2PEERPORT