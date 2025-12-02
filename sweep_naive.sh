#!/bin/bash

# Usage: ./sweep_naive.sh [M_VALUES...]
# Example: ./sweep_naive.sh 16 32 64

# Constant W and DUT
W_VAL=2048
DUT="naiveadder2048b"

if [ "$#" -eq 0 ]; then
    M_LIST=(2 4 8 16 32 64 128 256 512 1024 2048) 
else
    M_LIST=("$@")
fi

mkdir -p logs
SWEEP_OUT="sweep_results_${DUT}"
mkdir -p "$SWEEP_OUT"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="logs/${DUT}_SWEEP_W${W_VAL}_${TIMESTAMP}.log"

echo "---------------------------------------"
echo "Logging output to: $LOG_FILE"
echo "Safe Results dir : $SWEEP_OUT"
echo "---------------------------------------"

exec > >(tee -a "$LOG_FILE") 2>&1

chmod +x ./extract.sh

check_status() {
    if [[ $? -ne 0 ]]; then
        echo -e "\n\033[1;31m[ERROR] Step failed! Exiting.\033[0m"
        exit 1
    fi
}

echo -e "\n\033[1;34m=======================================\033[0m"
echo -e "\033[1;37mStarting Sweep for: \033[1;32m$DUT\033[0m"
echo "Fixed Width      : W=$W_VAL"
echo "M Values to run  : ${M_LIST[*]}"
echo -e "\033[1;34m=======================================\033[0m\n"

for M_VAL in "${M_LIST[@]}"; do
    
    echo -e "\n\033[1;35m--------------------------------------------------\033[0m"
    echo -e "\033[1;35m   Running Flow for M = $M_VAL \033[0m"
    echo -e "\033[1;35m--------------------------------------------------\033[0m"

    MAKE_FLAGS="DUT=$DUT W=$W_VAL M=$M_VAL ARCH_PARAM_NAME=M ARCH_PARAM_VAL=$M_VAL"

    echo -e "\033[1;33m[Cleaning] Previous build artifacts...\033[0m"
    rm -rf sim impl
    
    echo -e "\033[1;36m[Synthesizing] M=$M_VAL ...\033[0m"
    make synth $MAKE_FLAGS
    check_status

    echo -e "\033[1;36m[Fitting] M=$M_VAL ...\033[0m"
    make fit $MAKE_FLAGS
    check_status

    echo -e "\033[1;36m[Extracting] M=$M_VAL ...\033[0m"
    make extract $MAKE_FLAGS
    check_status

    EXPECTED_FILE="results/${DUT}_W${W_VAL}_M${M_VAL}.csv"
    SAFE_FILE="${SWEEP_OUT}/${DUT}_W${W_VAL}_M${M_VAL}.csv"

    if [[ -f "$EXPECTED_FILE" ]]; then
        cp "$EXPECTED_FILE" "$SAFE_FILE"
        echo -e "\033[1;32m[SUCCESS] Result saved to: $SAFE_FILE\033[0m"
    else
        FALLBACK_FILE="results/${DUT}_W${W_VAL}_.csv" 
        if [[ -f "$FALLBACK_FILE" ]]; then
             cp "$FALLBACK_FILE" "$SAFE_FILE"
             echo -e "\033[1;32m[SUCCESS] Result saved to: $SAFE_FILE (from fallback)\033[0m"
        else
             echo -e "\033[1;31m[ERROR] Output CSV not found for M=$M_VAL\033[0m"
        fi
    fi

done

FINAL_OUTPUT="sweep_${DUT}_results.csv"

echo -e "\n\033[1;34m=======================================\033[0m"
echo -e "\033[1;37mCombining Results into: $FINAL_OUTPUT\033[0m"

if [ -z "$(ls -A $SWEEP_OUT/*.csv 2>/dev/null)" ]; then
   echo "No CSV files found in $SWEEP_OUT"
else
   awk 'FNR==1 && NR!=1{next;}{print}' $(ls $SWEEP_OUT/*.csv | sort -V) > $FINAL_OUTPUT
   echo -e "\033[1;32m[DONE] Combined $(ls $SWEEP_OUT/*.csv | wc -l) files.\033[0m"
   
   echo -e "\nSummary:"
   cat $FINAL_OUTPUT
fi

echo -e "\033[1;34m=======================================\033[0m"
