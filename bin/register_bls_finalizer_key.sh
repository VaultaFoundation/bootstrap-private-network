#!/usr/bin/env bash

####
# Once private network is setup and running with legacy consensus algo
# we can switch over to new finality method
# For each producers we will register new BLS keys
# and `switchtosvnn` will activate Savanna Algorithm
####

ENDPOINT=$1
# Producer Name
PRODUCER_NAME=$2
# First array starts from the second argument to the 22st argument
BLS_PUBLIC_KEY=$3
# Second array starts from the 23rd argument to the 43rd argument
BLS_PROOF_POSSESION=$4

# New System Contracts Replace with actions regfinkey, and switchtosvnn
# regfinkey [producer name] [public key] [proof of possession]
# void system_contract::regfinkey( const name& finalizer_name, const std::string& finalizer_key, const std::string& proof_of_possession)
set -x
cleos --url $ENDPOINT push action eosio regfinkey "{\"finalizer_name\":\"${PRODUCER_NAME:?}\", \
                            \"finalizer_key\":\"${BLS_PUBLIC_KEY:?}\", \
                            \"proof_of_possession\":\"${BLS_PROOF_POSSESION:?}\"}" -p ${PRODUCER_NAME:?}

sleep 1
set +x