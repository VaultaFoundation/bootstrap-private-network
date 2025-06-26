#!/usr/bin/env bash

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <ENDPOINT_ONE> <WALLET_DIR> [NUM_PRODUCERS] [SPLIT]"
  exit 1
fi

ENDPOINT_ONE=$1
WALLET_DIR=$2
NUM_PRODUCERS=${3:-3}
SPLIT=${4:-THIRDS}
DIVISOR=3

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
"${SCRIPT_DIR}"/open_wallet.sh "$WALLET_DIR" dev

# register producers error out if vars not set
# may not go through entire loop is NUM_PRODUCERS less then 26; default is 3
# split is the breakout of producer keys THIRDS or HALVES
# THIRDS divide up keys into three groups, one group for one nodeos process
# HALFS divide up key into two groups, one group for the first two nodeos process

if [ "$SPLIT" == "HALVES" ]; then
    DIVISOR=2
fi

switch_groups() {
    # switch groups 
    ((group_count++))
    if (( group_count >= NUMBER_OF_KEYS_PER_GROUP )); then
        group_count=0
        # update group names 
        # accumulate remainding items in to group TWO if HALVES
        # accumulate remaining items into group THREE if THIRDS
        case "$GROUP_NAME" in
            "ONE")
                GROUP_NAME="TWO";;
            "TWO")
                GROUP_NAME="THREE";;
            "THREE")
                ;;
            *)
                GROUP_NAME="ONE";;
        esac
    fi
}


# extra added to put remainders in first grouping
NUMBER_OF_KEYS_PER_GROUP=$(( (NUM_PRODUCERS + DIVISOR - 1) / DIVISOR ))
group_count=0
producer_created=0
all_producer_names=""
GROUP_NAME="ONE"
for producer_name in bpa bpb bpc bpd bpe bpf bpg bph bpi bpj bpk bpl bpm bpn bpo bpp bpq bpr bps bpt bpu bpv bpw bpx bpy bpz 
do
    # track producers for voting later
    all_producer_names="${all_producer_names}${producer_name} "
    
    # First time only need one BLS per node
    SIG_GROUP_FILE="${WALLET_DIR:?}/GROUP_${GROUP_NAME}.keys"
    if [[ ! -f "$SIG_GROUP_FILE" ]]; then
        # BLS KEYS FOR FINALIZER 
        spring-util bls create key --to-console > "${WALLET_DIR:?}"/"${producer_name}.finalizer.key"

        BLS_PUB_KEY=$(grep Public "${WALLET_DIR:?}"/"${producer_name}.finalizer.key" | cut -d: -f2 | sed 's/ //g')
        BLS_PRV_KEY=$(grep Private "${WALLET_DIR:?}"/"${producer_name}.finalizer.key" | cut -d: -f2 | sed 's/ //g')
        BLS_PROOF_POS=$(grep Possession "${WALLET_DIR:?}"/"${producer_name}.finalizer.key" | cut -d: -f2 | sed 's/ //g')
    
        # on chain registration 
        "$SCRIPT_DIR"/register_bls_finalizer_key.sh "$ENDPOINT_ONE" \
              "${producer_name}" "$BLS_PUB_KEY" "$BLS_PROOF_POS"

        printf " --signature-provider ${BLS_PUB_KEY}=KEY:${BLS_PRV_KEY} " > "$SIG_GROUP_FILE"
    fi
    
    PRODUCER_GROUP_FILE="${WALLET_DIR:?}/GROUP_${GROUP_NAME}.producers"
    if [[ ! -f "$PRODUCER_GROUP_FILE" ]]; then
        touch "$PRODUCER_GROUP_FILE"
    fi
    
    # head because we want the first match; they may be multiple keys
    PRIVATE_KEY=$(grep Private "$WALLET_DIR/${producer_name}.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
    PUBLIC_KEY=$(grep Public "$WALLET_DIR/${producer_name}.keys" | head -1 | cut -d: -f2 | sed 's/ //g')
    
    if [[ -z "$PRIVATE_KEY" || -z "$PUBLIC_KEY" ]]; then
        echo "Error: Missing keys for $producer_name not found in $WALLET_DIR/${producer_name}.keys"
        exit 1
    fi

    # register as producer
    cleos --url "$ENDPOINT_ONE" system regproducer "${producer_name}" "${PUBLIC_KEY}"

    # Accumulate producer names will be used later to start nodeos
    printf " --producer-name $producer_name " >> "$PRODUCER_GROUP_FILE"
    # Accumulate signatures used later in nodeos setup
    printf " --signature-provider ${PUBLIC_KEY}=KEY:${PRIVATE_KEY} " >> "$SIG_GROUP_FILE"

    # updates GROUP_NAME
    switch_groups

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
  cleos --url "$ENDPOINT_ONE" system voteproducer prods "${user_name}" ${all_producer_names}
done
