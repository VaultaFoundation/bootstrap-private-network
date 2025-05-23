#!/usr/bin/env bash

####################
# Extends who can execute active permissions for core accounts
# includes eosio and core.vaulta accounts
#####################

ENDPOINT_ONE=$1
SCRIPT_DIR=$2
WALLET_DIR=$3

# Make sure wallet is open 
"$SCRIPT_DIR"/open_wallet.sh "$WALLET_DIR"

VAULTA_PUBLIC_KEY=$(grep Public "${WALLET_DIR}"/core.vaulta.keys | head -1 | cut -d: -f2 | sed 's/ //g')
EOS_ROOT_PUBLIC_KEY=$(grep Public "${WALLET_DIR}"/finality-test-network.keys | head -1 | cut -d: -f2 | sed 's/ //g')

# Lets extent authorties to block producers so they can MSIG
# remove key access
# delegate active permissions
cat > $HOME/eosio_required_auth.json << EOF
{
  "threshold": 2,
  "keys": [],
  "accounts": [
    {
      "permission": {
        "actor": "bpa",
        "permission": "active"
      },
      "weight": 1
    },
    {
      "permission": {
        "actor": "bpb",
        "permission": "active"
      },
      "weight": 1
    },
    {
      "permission": {
        "actor": "bpc",
        "permission": "active"
      },
      "weight": 1
    }
  ],
  "waits": []
}
EOF
cleos  --url $ENDPOINT_ONE set account permission eosio active $HOME/eosio_required_auth.json
rm $HOME/eosio_required_auth.json

# Lets extent authorties to block producers so they can MSIG
# keep our access by key 
cat > $HOME/vaulta_required_auth.json << EOF
{
  "threshold": 2,
  "keys": [
    {
      "key": "${VAULTA_PUBLIC_KEY}",
      "weight": 2
    }
  ],
  "accounts": [
    {
      "permission": {
        "actor": "bpa",
        "permission": "active"
      },
      "weight": 1
    },
    {
      "permission": {
        "actor": "bpb",
        "permission": "active"
      },
      "weight": 1
    },
    {
      "permission": {
        "actor": "bpc",
        "permission": "active"
      },
      "weight": 1
    }
  ],
  "waits": []
}
EOF
cleos set account permission core.vaulta active $HOME/vaulta_required_auth.json -pcore.vaulta@active
rm $HOME/vaulta_required_auth.json
