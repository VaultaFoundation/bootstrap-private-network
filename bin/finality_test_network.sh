#!/usr/bin/env bash

####
# Once antelope software is build and installed
# script to manage private network
# CREATE new network with 3 nodes
# CLEAN out data from previous network
# STOP all nodes on network
# START 3 node network
# BACKUP take snapshots on each running nodeos
####

# config information
NODEOS_ONE_PORT=8888
NODEOS_TWO_PORT=6888
NODEOS_THREE_PORT=7888
ENDPOINT="http://127.0.0.1:${NODEOS_ONE_PORT}"

COMMAND=${1:-"NA"}
ROOT_DIR="/bigata1/savanna"
LOG_DIR="/bigata1/log"
WALLET_DIR=${HOME}/eosio-wallet
CONTRACT_DIR="/local/VaultaFoundation/repos/system-contracts/build/contracts"
VALUTA_CONTRACT_DIR="/local/VaultaFoundation/repos/vaulta-system-contract/build/contracts"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
GENESIS_FILE="/local/VaultaFoundation/repos/bootstrap-private-network/config/genesis.json"
CONFIG_FILE="/local/VaultaFoundation/repos/bootstrap-private-network/config/config.ini"
LOGGING_JSON="/local/VaultaFoundation/repos/bootstrap-private-network/config/logging.json"

######
# Stop Function to shutdown all nodes
#####
stop_func() {
  MY_ID=$(id -u)
  for p in $(ps -u $MY_ID | grep nodeos | sed -e 's/^[[:space:]]*//' | cut -d" " -f1); do
    echo $p && kill -15 $p
  done
  echo "waiting for production network to quiesce..."
  sleep 5
}
### END STOP Command

#####
# Check Percent Used Space
#####
check_used_space() {
  # check used space ; threshhold is 90%
  threshold=90
  percent_used=$(df -h "${ROOT_DIR:?}" | awk 'NR==2 {print $5}' | sed 's/%//')
  if [ ${percent_used:-100} -gt ${threshold} ]; then
    echo "ERROR: ${ROOT_DIR} is full at ${percent_used:-100}%. Must be less then ${threshold}%."
    return 127
  else
    return 0
  fi
}

#####
# START/CREATE Function to startup all nodes
####
start_func() {
  COMMAND=$1

  check_used_space
  USED_SPACE=$?

  if [ $USED_SPACE -ne 0 ]; then
    echo "Exiting not enough free space"
    exit 127
  fi

  # create private key
  [ ! -d "$WALLET_DIR" ] && mkdir -p "$WALLET_DIR"
  [ ! -s "$WALLET_DIR"/finality-test-network.keys ] && cleos create key --to-console > "$WALLET_DIR"/finality-test-network.keys
  # head because we want the first match; they may be multiple keys
  EOS_ROOT_PRIVATE_KEY=$(grep Private "${WALLET_DIR}"/finality-test-network.keys | head -1 | cut -d: -f2 | sed 's/ //g')
  EOS_ROOT_PUBLIC_KEY=$(grep Public "${WALLET_DIR}"/finality-test-network.keys | head -1 | cut -d: -f2 | sed 's/ //g')
  # create keys for first three producers
  for producer_name in bpa bpb bpc
  do
      [ ! -s "$WALLET_DIR/${producer_name}.keys" ] && cleos create key --to-console > "$WALLET_DIR/${producer_name}.keys"
      spring-util bls create key --to-console > "${WALLET_DIR:?}"/"${producer_name}.finalizer.key"
  done

  # create initialize genesis file; create directories; copy cofigs into place
  if [ "$COMMAND" == "CREATE" ]; then
    NOW=$(date +%FT%T.%3N)
    sed "s/\"initial_key\": \".*\",/\"initial_key\": \"${EOS_ROOT_PUBLIC_KEY}\",/" $GENESIS_FILE > /tmp/genesis.json
    sed "s/\"initial_timestamp\": \".*\",/\"initial_timestamp\": \"${NOW}\",/" /tmp/genesis.json > ${ROOT_DIR}/genesis.json
    [ ! -d "$LOG_DIR" ] && mkdir -p "$LOG_DIR"
    [ ! -d "$ROOT_DIR"/nodeos-one/data ] && mkdir -p "$ROOT_DIR"/nodeos-one/data
    [ ! -d "$ROOT_DIR"/nodeos-two/data ] && mkdir -p "$ROOT_DIR"/nodeos-two/data
    [ ! -d "$ROOT_DIR"/nodeos-three/data ] && mkdir -p "$ROOT_DIR"/nodeos-three/data
    # setup common config, shared by all nodoes instances
    cp "${CONFIG_FILE}" ${ROOT_DIR}/config.ini
    cp "${LOGGING_JSON}" ${ROOT_DIR}/logging.json
  fi

  # setup wallet
  "$SCRIPT_DIR"/open_wallet.sh "$WALLET_DIR"
  # Import Root Private Key
  cleos wallet import --name finality-test-network-wallet --private-key $EOS_ROOT_PRIVATE_KEY

  # start nodeos one always allow stale production
  if [ "$COMMAND" == "CREATE" ]; then
    nodeos --genesis-json ${ROOT_DIR}/genesis.json --agent-name "Finality Test Node One" \
      --http-server-address 0.0.0.0:${NODEOS_ONE_PORT} \
      --p2p-listen-endpoint 0.0.0.0:1444 \
      --enable-stale-production \
      --producer-name eosio \
      --signature-provider ${EOS_ROOT_PUBLIC_KEY}=KEY:${EOS_ROOT_PRIVATE_KEY} \
      --config "$ROOT_DIR"/config.ini \
      --data-dir "$ROOT_DIR"/nodeos-one/data > $LOG_DIR/nodeos-one.log 2>&1 &
    NODEOS_ONE_PID=$!

    # create accounts, activate protocols, create tokens, set system contracts
    sleep 1
    "$SCRIPT_DIR"/boot_actions.sh "$ENDPOINT" "$CONTRACT_DIR" "$EOS_ROOT_PUBLIC_KEY"
    sleep 1
    "$SCRIPT_DIR"/initalize_A_tokens.sh "$ENDPOINT" "$VALUTA_CONTRACT_DIR" "$WALLET_DIR" "$SCRIPT_DIR"
    "$SCRIPT_DIR"/add_time_func.sh "$ENDPOINT" 
    sleep 1
    # create producer and user accounts, stake EOS
    "$SCRIPT_DIR"/create_accounts.sh "$ENDPOINT" "$CONTRACT_DIR"
    sleep 1
    # register producers and users vote for producers
    "$SCRIPT_DIR"/block_producer_setup.sh "$ENDPOINT" "$WALLET_DIR"
    # update active permisions for eosio and core.vaulta account
    "$SCRIPT_DIR"/set_authorities.sh "$ENDPOINT" "$SCRIPT_DIR" "$WALLET_DIR"
    # create null.vaulta user and noop contracts
    "$SCRIPT_DIR"/noop_contract.sh "$ENDPOINT" "$WALLET_DIR" "$SCRIPT_DIR"
    # need a long sleep here to allow time for new production schedule to settle
    echo "please wait 5 seconds while we wait for new producer schedule to settle"
    sleep 5
    kill -15 $NODEOS_ONE_PID
    # wait for shutdown
    sleep 5
  fi

  # if CREATE we bootstraped the node and killed it
  # if START we have no node running
  # either way we need to start Node One
  # PRODUCER KEYS
  BPA_PRIVATE_KEY=$(grep Private "$WALLET_DIR/bpa.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
  BPA_PUBLIC_KEY=$(grep Public "$WALLET_DIR/bpa.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
  # BLS KEYS FOR FINALIZER
  BPA_BLS_PUB_KEY=$(grep Public "${WALLET_DIR}/bpa.finalizer.key" | cut -d: -f2 | sed 's/ //g')
  BPA_BLS_PRV_KEY=$(grep Private "${WALLET_DIR}/bpa.finalizer.key" | cut -d: -f2 | sed 's/ //g')
  BPA_BLS_POS=$(grep Possession "${WALLET_DIR}/bpa.finalizer.key" | cut -d: -f2 | sed 's/ //g') 
  # NODEOS COMMAND 
  nodeos --agent-name "Finality Test Node One" \
    --http-server-address 0.0.0.0:${NODEOS_ONE_PORT} \
    --p2p-listen-endpoint 0.0.0.0:1444 \
    --enable-stale-production \
    --producer-name bpa \
    --signature-provider ${BPA_PUBLIC_KEY}=KEY:${BPA_PRIVATE_KEY} \
    --signature-provider ${BPA_BLS_PUB_KEY}=KEY:${BPA_BLS_PRV_KEY} \
    --config "$ROOT_DIR"/config.ini \
    --data-dir "$ROOT_DIR"/nodeos-one/data \
    --p2p-peer-address 127.0.0.1:2444 \
    --p2p-peer-address 127.0.0.1:3444 --logconf "$ROOT_DIR"/logging.json > $LOG_DIR/nodeos-one.log 2>&1 &

  # start nodeos two
  echo "please wait while we fire up the second node"
  sleep 2

  # PRODUCER KEYS
  BPB_PRIVATE_KEY=$(grep Private "$WALLET_DIR/bpb.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
  BPB_PUBLIC_KEY=$(grep Public "$WALLET_DIR/bpb.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
  # BLS KEYS FOR FINALIZER
  BPB_BLS_PUB_KEY=$(grep Public "${WALLET_DIR}/bpb.finalizer.key" | cut -d: -f2 | sed 's/ //g')
  BPB_BLS_PRV_KEY=$(grep Private "${WALLET_DIR}/bpb.finalizer.key" | cut -d: -f2 | sed 's/ //g')
  BPB_BLS_POS=$(grep Possession "${WALLET_DIR}/bpb.finalizer.key" | cut -d: -f2 | sed 's/ //g')
  # NODEOS COMMAND 
  if [ "$COMMAND" == "CREATE" ]; then
    nodeos --genesis-json ${ROOT_DIR}/genesis.json --agent-name "Finality Test Node Two" \
      --http-server-address 0.0.0.0:${NODEOS_TWO_PORT} \
      --p2p-listen-endpoint 0.0.0.0:2444 \
      --enable-stale-production \
      --producer-name bpb \
      --signature-provider ${BPB_PUBLIC_KEY}=KEY:${BPB_PRIVATE_KEY} \
      --signature-provider ${BPB_BLS_PUB_KEY}=KEY:${BPB_BLS_PRV_KEY} \
      --config "$ROOT_DIR"/config.ini \
      --data-dir "$ROOT_DIR"/nodeos-two/data \
      --p2p-peer-address 127.0.0.1:1444 \
      --p2p-peer-address 127.0.0.1:3444 > $LOG_DIR/nodeos-two.log 2>&1 &
  else
    nodeos --agent-name "Finality Test Node Two" \
      --http-server-address 0.0.0.0:${NODEOS_TWO_PORT} \
      --p2p-listen-endpoint 0.0.0.0:2444 \
      --enable-stale-production \
      --producer-name bpb \
      --signature-provider ${BPB_PUBLIC_KEY}=KEY:${BPB_PRIVATE_KEY} \
      --signature-provider ${BPB_BLS_PUB_KEY}=KEY:${BPB_BLS_PRV_KEY} \
      --config "$ROOT_DIR"/config.ini \
      --data-dir "$ROOT_DIR"/nodeos-two/data \
      --p2p-peer-address 127.0.0.1:1444 \
      --p2p-peer-address 127.0.0.1:3444 > $LOG_DIR/nodeos-two.log 2>&1 &
  fi
  echo "please wait while we fire up the third node"
  sleep 5

  # PRODUCER KEYS
  BPC_PRIVATE_KEY=$(grep Private "$WALLET_DIR/bpc.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
  BPC_PUBLIC_KEY=$(grep Public "$WALLET_DIR/bpc.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
  # BLS KEYS FOR FINALIZER
  BPC_BLS_PUB_KEY=$(grep Public "${WALLET_DIR}/bpc.finalizer.key" | cut -d: -f2 | sed 's/ //g')
  BPC_BLS_PRV_KEY=$(grep Private "${WALLET_DIR}/bpc.finalizer.key" | cut -d: -f2 | sed 's/ //g')
  BPC_BLS_POS=$(grep Possession "${WALLET_DIR}/bpc.finalizer.key" | cut -d: -f2 | sed 's/ //g')
  # NODEOS COMMAND 
  if [ "$COMMAND" == "CREATE" ]; then
    nodeos --genesis-json ${ROOT_DIR}/genesis.json --agent-name "Finality Test Node Three" \
      --http-server-address 0.0.0.0:${NODEOS_THREE_PORT} \
      --p2p-listen-endpoint 0.0.0.0:3444 \
      --enable-stale-production \
      --producer-name bpc \
      --signature-provider ${BPC_PUBLIC_KEY}=KEY:${BPC_PRIVATE_KEY} \
      --signature-provider ${BPC_BLS_PUB_KEY}=KEY:${BPC_BLS_PRV_KEY} \
      --config "$ROOT_DIR"/config.ini \
      --data-dir "$ROOT_DIR"/nodeos-three/data \
      --p2p-peer-address 127.0.0.1:1444 \
      --p2p-peer-address 127.0.0.1:2444 > $LOG_DIR/nodeos-three.log 2>&1 &
  else
    nodeos --agent-name "Finality Test Node Three" \
      --http-server-address 0.0.0.0:${NODEOS_THREE_PORT} \
      --p2p-listen-endpoint 0.0.0.0:3444 \
      --enable-stale-production \
      --producer-name bpc \
      --signature-provider ${BPC_PUBLIC_KEY}=KEY:${BPC_PRIVATE_KEY} \
      --signature-provider ${BPC_BLS_PUB_KEY}=KEY:${BPC_BLS_PRV_KEY} \
      --config "$ROOT_DIR"/config.ini \
      --data-dir "$ROOT_DIR"/nodeos-three/data \
      --p2p-peer-address 127.0.0.1:1444 \
      --p2p-peer-address 127.0.0.1:2444 > $LOG_DIR/nodeos-three.log 2>&1 &
  fi
  
  if [ ! -f $LOG_DIR/registered_bls_keys.txt ]; then 
    sleep 2
    "$SCRIPT_DIR"/open_wallet.sh "$WALLET_DIR"
    # Now Register the Finalizer Keys On Each Node You could register these on any node
    # args: producer_name, bls_pub_key, bls_proof_of_posession
    # Simply call to `push action eosio regfinkey`
    "$SCRIPT_DIR"/register_bls_finalizer_key.sh http://127.0.0.1:${NODEOS_ONE_PORT} \
              bpa "$BPA_BLS_PUB_KEY" "$BPA_BLS_POS"
    "$SCRIPT_DIR"/register_bls_finalizer_key.sh http://127.0.0.1:${NODEOS_TWO_PORT} \
              bpb "$BPB_BLS_PUB_KEY" "$BPB_BLS_POS"
    "$SCRIPT_DIR"/register_bls_finalizer_key.sh http://127.0.0.1:${NODEOS_THREE_PORT} \
              bpc "$BPC_BLS_PUB_KEY" "$BPC_BLS_POS"
    # record keys as registered 
    touch $LOG_DIR/registered_bls_keys.txt
  fi
  echo "waiting for production network to sync up..."
  sleep 18
  
  # Activate SAVANNA 
  if [ "$COMMAND" == "CREATE" ] && [ -f $LOG_DIR/registered_bls_keys.txt ] && [ ! -f $LOG_DIR/savanna_activated.txt ]
  then
    echo "Activating SAVANNA Consensus "
    "$SCRIPT_DIR"/open_wallet.sh "$WALLET_DIR"
    cleos --url $ENDPOINT push action eosio switchtosvnn '{}' -p eosio
    touch $LOG_DIR/savanna_activated.txt
    
    echo "please wait for transition to Savanna consensus"
    sleep 30
    grep 'Transitioning to savanna' "$LOG_DIR"/nodeos-one.log
    grep 'Transition to instant finality' "$LOG_DIR"/nodeos-one.log
  fi
}
## end START/CREATE COMMAND
echo "STARTING COMMAND ${COMMAND}"

if [ "$COMMAND" == "NA" ]; then
  echo "usage: finality_test_network.sh [CREATE|START|CLEAN|STOP|SAVANNA]"
  exit 1
fi

if [ "$COMMAND" == "CLEAN" ]; then
    for d in nodeos-one nodeos-two nodeos-three; do
        [ -f "$ROOT_DIR"/${d}/data/blocks/blocks.log ] && rm -f "$ROOT_DIR"/${d}/data/blocks/blocks.log
        [ -f "$ROOT_DIR"/${d}/data/blocks/blocks.index ] && rm -f "$ROOT_DIR"/${d}/data/blocks/blocks.index
        [ -f "$ROOT_DIR"/${d}/data/state/shared_memory.bin ] && rm -f "$ROOT_DIR"/${d}/data/state/shared_memory.bin
        [ -f "$ROOT_DIR"/${d}/data/state/code_cache.bin ] && rm -f "$ROOT_DIR"/${d}/data/state/code_cache.bin
        [ -f "$ROOT_DIR"/${d}/data/state/chain_head.dat ] && rm -f "$ROOT_DIR"/${d}/data/state/chain_head.dat
        [ -f "$ROOT_DIR"/${d}/data/blocks/reversible/fork_db.dat ] && rm -f "$ROOT_DIR"/${d}/data/blocks/reversible/fork_db.dat
        [ -f "$LOG_DIR"/registered_bls_keys.txt ] && rm -f "$LOG_DIR"/registered_bls_keys.txt
        [ -f "$LOG_DIR"/savanna_activated.txt ] && rm -f "$LOG_DIR"/savanna_activated.txt
    done
fi

if [ "$COMMAND" == "CREATE" ] || [ "$COMMAND" == "START" ]; then
  start_func $COMMAND
fi

if [ "$COMMAND" == "STOP" ]; then
  stop_func
fi

if [ "$COMMAND" == "BACKUP" ]; then
  for loc in "http://127.0.0.1:${NODEOS_ONE_PORT}" "http://127.0.0.1:${NODEOS_TWO_PORT}" "http://127.0.0.1:${NODEOS_THREE_PORT}"
  do
    $SCRIPT_DIR/do_snapshot.sh $loc
  done
fi

echo "COMPLETED COMMAND ${COMMAND}"
