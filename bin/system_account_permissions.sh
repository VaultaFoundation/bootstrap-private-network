#!/usr/bin/env bash

ENDPOINT_ONE=$1
WALLET_DIR=$2

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
"${SCRIPT_DIR}"/open_wallet.sh "$WALLET_DIR" root

cat > $HOME/wram_active_auth.json << EOF
{
  "threshold": 2,
  "keys": [],
  "accounts": [
    {
      "permission": {
          "actor":"eosio",
          "permission": "active"
      },
      "weight": 1
    },
    {
      "permission": {
          "actor": "eosio.prods",
          "permission": "prod.minor"
      },
      "weight": 1
    },
  ],
  "waits": []
}
EOF
cat > $HOME/eosio_accounts_active_auth.json << EOF
{
  "threshold": 1,
  "keys": [],
  "accounts": [
    {
      "permission": {
          "actor":"eosio",
          "permission": "active"
      },
      "weight": 1
    }
  ],
  "waits": []
}
EOF

# set active to eosio@active 
for account in eosio.bpay eosio.msig eosio.names eosio.ram eosio.ramfee eosio.saving eosio.stake eosio.token eosio.vpay eosio.rex eosio.reserv; do
   cleos --url $ENDPOINT_ONE set account permission ${account} active $HOME/eosio_accounts_active_auth.json -p${account}@owner
done

# wram special
cleos --url $ENDPOINT_ONE set account permission eosio.wram active $HOME/wram_active_auth.json -peosio.wram

# enable set code 
for account in eosio.bpay eosio.saving eosio.fees eosio.reward eosio.wram; do
  cleos -u $ENDPOINT_ONE set account permission ${account} active --add-code -p${account}@owner
  cleos -u $ENDPOINT_ONE push action eosio setpriv "[\"${account}\", 1]" -peosio
done

# set owner to eosio@active
for account in eosio.bpay eosio.msig eosio.names eosio.ram eosio.ramfee eosio.saving eosio.stake eosio.token eosio.vpay eosio.rex eosio.fees eosio.reward eosio.wram eosio.reserv; do
    cleos --url $ENDPOINT_ONE set account permission ${account} owner $HOME/eosio_accounts_active_auth.json -p${account}@owner
done


