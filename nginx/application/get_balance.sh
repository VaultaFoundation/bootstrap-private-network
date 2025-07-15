#!/usr/bin/env bash

USER_NAME=${1}

# Get eosio.token account rows as JSON
EOSIO_ROWS=$(cleos --url http://127.0.0.1:8888 get table eosio.token $USER_NAME accounts | jq -c '.rows[]?')

# Get core.vaulta account rows as JSON
VAULTA_ROWS=$(cleos --url http://127.0.0.1:8888 get table core.vaulta $USER_NAME accounts | jq -c '.rows[]?')

# Start the JSON output
echo -n '{ "rows": ['

# Join entries with commas only if they exist
FIRST=true

if [[ -n "$EOSIO_ROWS" ]]; then
    while IFS= read -r row; do
        if $FIRST; then FIRST=false; else echo -n ','; fi
        echo -n "$row"
    done <<< "$EOSIO_ROWS"
fi

if [[ -n "$VAULTA_ROWS" ]]; then
    while IFS= read -r row; do
        if $FIRST; then FIRST=false; else echo -n ','; fi
        echo -n "$row"
    done <<< "$VAULTA_ROWS"
fi

# Close JSON
echo ']}'