#!/usr/bin/env bash

####
# Used to open wallet to store key
# needed to create accounts, activate features, and create contracts
# called from finality_test_network.sh
####

WALLET_DIR=$1
TYPE=${2:-dev}

# setup wallets, open wallet, add keys if needed
[ ! -d "$WALLET_DIR" ] && mkdir -p "$WALLET_DIR"
if [ ! -f "${WALLET_DIR}"/${TYPE}-test-network-wallet.wallet ]; then
  cleos wallet create --name ${TYPE}-test-network-wallet --file "${WALLET_DIR}"/${TYPE}-test-network-wallet.pw
fi
IS_WALLET_OPEN=$(cleos wallet list | grep ${TYPE}-test-network-wallet | grep -F '*' | wc -l)
# not open then it is locked so unlock it
if [ $IS_WALLET_OPEN -lt 1 ]; then
  cat "${WALLET_DIR}"/${TYPE}-test-network-wallet.pw | cleos wallet unlock --name ${TYPE}-test-network-wallet --password
fi
