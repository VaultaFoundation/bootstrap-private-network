#!/usr/bin/env bash

ENDPOINT_ONE=$1
WALLET_DIR=$2
NUM_PRODUCERS=${3:-3}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
"${SCRIPT_DIR}"/open_wallet.sh "$WALLET_DIR" root
"${SCRIPT_DIR}"/open_wallet.sh "$WALLET_DIR" admin
"${SCRIPT_DIR}"/open_wallet.sh "$WALLET_DIR" dev
"${SCRIPT_DIR}"/open_wallet.sh "$WALLET_DIR" users

cleos --url $ENDPOINT_ONE transfer eosio vaulta "10000 EOS" "init funding"
cleos --url $ENDPOINT_ONE system buyram eosio vaulta "1000 EOS"

# create admin account 
admin_name="admin.vaulta"
[ ! -s "$WALLET_DIR/${admin_name}.keys" ] && cleos create key --to-console > "$WALLET_DIR/${admin_name}.keys"
# head because we want the first match; they may be multiple keys
ADMIN_PRIVATE_KEY=$(grep Private "$WALLET_DIR/${admin_name}.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
ADMIN_PUBLIC_KEY=$(grep Public "$WALLET_DIR/${admin_name}.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
cleos wallet import --name admin-test-network-wallet --private-key $ADMIN_PRIVATE_KEY

cleos --url $ENDPOINT_ONE system newaccount eosio ${admin_name:?} ${ADMIN_PUBLIC_KEY:?} --stake-net "50 EOS" --stake-cpu "500 EOS" --buy-ram "1000 EOS"
# get some spending money
cleos --url $ENDPOINT_ONE transfer eosio ${admin_name} "100 EOS" "init funding"
# self stake some net and cpu
cleos --url $ENDPOINT_ONE system delegatebw ${admin_name} ${admin_name} "400.0 EOS" "400.0 EOS"


# create producers error out if vars not set
# may not go through entire loop is NUM_PRODUCERS less then 26; default is 3
producer_created=0
for producer_name in bpa bpb bpc bpd bpe bpf bpg bph bpi bpj bpk bpl bpm bpn bpo bpp bpq bpr bps bpt bpu bpv bpw bpx bpy bpz 
do
    [ ! -s "$WALLET_DIR/${producer_name}.keys" ] && cleos create key --to-console > "$WALLET_DIR/${producer_name}.keys"
    # head because we want the first match; they may be multiple keys
    PRIVATE_KEY=$(grep Private "$WALLET_DIR/${producer_name}.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
    PUBLIC_KEY=$(grep Public "$WALLET_DIR/${producer_name}.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
    cleos wallet import --name dev-test-network-wallet --private-key $PRIVATE_KEY

    # 1550 staked per producer 
    cleos --url $ENDPOINT_ONE system newaccount eosio ${producer_name:?} ${PUBLIC_KEY:?} --stake-net "50 EOS" --stake-cpu "500 EOS" --buy-ram "1000 EOS"
    # get some spending money
    cleos --url $ENDPOINT_ONE transfer eosio ${producer_name} "100 EOS" "init funding"
    # self stake some net and cpu
    cleos --url $ENDPOINT_ONE system delegatebw ${producer_name} ${producer_name} "400.0 EOS" "400.0 EOS"
    
    # exit after num producers reached 
    ((producer_created++))
    if (( producer_created >= NUM_PRODUCERS )); then
        break
    fi
done


# create user keys
[ ! -s "$WALLET_DIR/user.keys" ] && cleos create key --to-console > "$WALLET_DIR/user.keys"
# head because we want the first match; they may be multiple keys
USER_PRIVATE_KEY=$(grep Private "$WALLET_DIR/user.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
USER_PUBLIC_KEY=$(grep Public "$WALLET_DIR/user.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
cleos wallet import --name users-test-network-wallet --private-key $USER_PRIVATE_KEY

for user_name in usera userb userc userd usere userf userg userh useri userj \
   userk userl userm usern usero userp userq userr users usert useru \
   userv userw userx usery userz
do
  # create user account
  cleos --url $ENDPOINT_ONE system newaccount eosio ${user_name:?} ${USER_PUBLIC_KEY:?} --stake-net "50 EOS" --stake-cpu "50 EOS" --buy-ram "100 EOS"
  # get some spending money
  cleos --url $ENDPOINT_ONE transfer eosio ${user_name} "65423000 EOS" "init funding"
  # stake 65,423,000 EOS x26 accounts = 1,700,998,000 EOS Total Staked 80.99% of 2.1B total funds
  cleos --url $ENDPOINT_ONE system delegatebw ${user_name} ${user_name} "32711500.0000 EOS" "32711500.0000 EOS"
done
