#!/usr/bin/env bash

####################
# Extends who can execute active permissions for core accounts
# includes eosio and core.vaulta accounts
#####################

ENDPOINT_ONE=$1
SCRIPT_DIR=$2
WALLET_DIR=$3
NUM_PRODUCERS=${4:-3}

# Make sure wallet is open 
"$SCRIPT_DIR"/open_wallet.sh "$WALLET_DIR" root

VAULTA_PUBLIC_KEY=$(grep Public "${WALLET_DIR}"/core.vaulta.keys | head -1 | cut -d: -f2 | sed 's/ //g')
EOS_ROOT_PUBLIC_KEY=$(grep Public "${WALLET_DIR}"/root-test-network.keys | head -1 | cut -d: -f2 | sed 's/ //g')


generate_permissions_json() {
  local N="$1"
  local json=''
  
  for ((i=0; i<N; i++)); do
    # Map i=0 to 'a', i=1 to 'b', ..., i=25 to 'z'
    letter=$(printf "\\x$(printf '%x' $((97 + i)))")

    json+="
  {
    \"permission\": {
      \"actor\": \"bp${letter}\",
      \"permission\": \"active\"
    },
    \"weight\": 1
  }"
    if (( i < N - 1 )); then
      json+=","
    fi
  done

  echo "$json"
}

producer_accounts=$(generate_permissions_json $NUM_PRODUCERS)
THRESHOLD=$(( NUM_PRODUCERS * 2 / 3 ))

# Lets extent authorties to block producers so they can MSIG
# remove key access
# delegate active permissions
cat > $HOME/eosio_required_auth.json << EOF
{
  "threshold": ${THRESHOLD},
  "keys": [
    {
      "key": "${EOS_ROOT_PUBLIC_KEY}",
      "weight": ${THRESHOLD}
    }
  ],
  "accounts": [
    {
      "permission": {
          "actor":"admin.vaulta",
          "permission": "active"
      },
      "weight": ${THRESHOLD}
    },
  ${producer_accounts}
  ],
  "waits": []
}
EOF
cleos  --url $ENDPOINT_ONE set account permission eosio active $HOME/eosio_required_auth.json -peosio@active
rm $HOME/eosio_required_auth.json

# Lets extent authorties to block producers so they can MSIG
# keep our access by key 
cat > $HOME/vaulta_required_auth.json << EOF
{
  "threshold": 15,
  "keys": [
    {
      "key": "${VAULTA_PUBLIC_KEY}",
      "weight": 15
    }
  ],
  "accounts": [
     {"permission":{"actor":"admin.vaulta","weight":15}},
     ${producer_accounts}
  ],
  "waits": []
}
EOF
cleos set account permission core.vaulta active $HOME/vaulta_required_auth.json -pcore.vaulta@active
rm $HOME/vaulta_required_auth.json
