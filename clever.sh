#!/bin/bash

M_BEST=16
DUT="cleveradder2048b"
W_VAL=2048
WINNER_FILE="results/winner_clever.csv"

source env.sh

./sweep_clever.sh $M_BEST

SOURCE_CSV="sweep_results_${DUT}/${DUT}_W${W_VAL}_M${M_BEST}.csv"

mkdir -p results

if [[ -f "$SOURCE_CSV" ]]; then
    cp "$SOURCE_CSV" "$WINNER_FILE"
    echo -e "\n\033[1;32m[SUCCESS] Winner file populated: $WINNER_FILE\033[0m"
    echo "Content:"
    cat "$WINNER_FILE"
else
    echo -e "\n\033[1;31m[ERROR] Source CSV not found at: $SOURCE_CSV\033[0m"
    exit 1
fi
