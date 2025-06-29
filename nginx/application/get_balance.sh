#!/usr/bin/env bash

USER_NAME=${1}

printf '{ "rows": ['
cleos --url http://127.0.0.1:8888 get table eosio.token $USER_NAME accounts | jq '.rows[]'
printf ','
cleos --url http://127.0.0.1:8888 get table core.vaulta $USER_NAME accounts | jq '.rows[]'
printf ']}'