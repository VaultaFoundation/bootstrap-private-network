#!/usr/bin/env bash

ENDPOINT_ONE=$1
WALLET_DIR=$2
NUM_PRODUCERS=${3:-3}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
"${SCRIPT_DIR}"/open_wallet.sh "$WALLET_DIR" dev

# register producers error out if vars not set
# may not go through entire loop is NUM_PRODUCERS less then 26; default is 3
producer_created=0
for producer_name in bpa bpb bpc bpd bpe bpf bpg bph bpi bpj bpk bpl bpm bpn bpo bpp bpq bpr bps bpt bpu bpv bpw bpx bpy bpz 
do
    [ ! -s "$WALLET_DIR/${producer_name}.keys" ] && cleos create key --to-console > "$WALLET_DIR/${producer_name}.keys"
    # head because we want the first match; they may be multiple keys
    PRIVATE_KEY=$(grep Private "$WALLET_DIR/${producer_name}.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
    PUBLIC_KEY=$(grep Public "$WALLET_DIR/${producer_name}.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
    cleos wallet import --name dev-test-network-wallet --private-key $PRIVATE_KEY

    # register producer
    cleos --url "$ENDPOINT_ONE" system regproducer "${producer_name}" "${PUBLIC_KEY}"
    
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
cleos wallet import --name dev-test-network-wallet --private-key $USER_PRIVATE_KEY

for user_name in usera userb userc userd usere userf userg userh useri userj \
   userk userl userm usern usero userp userq userr users usert useru \
   userv userw userx usery userz
do
  # vote
  cleos --url $ENDPOINT_ONE system voteproducer prods ${user_name} bpa bpb bpc
done
