#!/bin/zsh
DIR=~/ece722-f25/labs-admin/lab4-sol
mkdir -p results
cp $DIR/results/gold.winner_*.csv ./results
cp $DIR/tb/test_*.sv ./tb
cp $DIR/Makefile .
cp $DIR/env.sh .

source env.sh

DUTS=("naiveadder2048b" "cleveradder2048b")
W=2048

declare -A dut_pass
declare -A dut_m

# make sure to create fresh new hex files
make data DUT=adder TESTS=1024

# Extract M values from student's winner files and test functionality
for DUT in "${DUTS[@]}"; do
    winner_name=${DUT/adder2048b/}  # naive or clever
    winner_file="results/winner_${winner_name}.csv"

    if [[ -f "$winner_file" ]]; then
        M=$(sed -n '2p' "$winner_file" | cut -d',' -f1)
        dut_m[$DUT]=$M

        # Test functionality with student's chosen M
        if make sim DUT=$DUT W=$W M=$M &>/dev/null && \
           make extract_sim DUT=$DUT W=$W M=$M &>/dev/null; then
            dut_pass[$DUT]=1
            echo "✓ $DUT M=$M W=$W"
        else
            dut_pass[$DUT]=0
            echo "✗ $DUT M=$M W=$W"
        fi
    else
        dut_pass[$DUT]=0
        dut_m[$DUT]="N/A"
        echo "✗ $DUT (no winner file)"
    fi
done

#chmod +x naive.sh clever.sh
#./naive.sh
#./clever.sh

# Function to compare winner files (freq only)
# Returns: score/1 (max 1 point)
compare_winner() {
    local student=$1
    local golden=$2

    # Check files exist
    [[ ! -f "$student" ]] && { echo "0/1"; return; }
    [[ ! -f "$golden" ]] && { echo "0/1"; return; }

    # Extract Fmax from data row (line 2)
    local s_fmax=$(sed -n '2p' "$student" | cut -d',' -f2)
    local g_fmax=$(sed -n '2p' "$golden" | cut -d',' -f2)

    # Validate: values must be non-empty
    [[ -z "$s_fmax" || -z "$g_fmax" ]] && { echo "0/1"; return; }

    # Validate: values must be valid numbers (not NaN, not text)
    if ! [[ "$s_fmax" =~ ^[0-9]+\.?[0-9]*$ ]] || \
       ! [[ "$g_fmax" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        echo "0/1"
        return
    fi

    # Validate: Fmax must be > 0 (can't have zero frequency)
    local fmax_valid=$(awk -v s="$s_fmax" -v g="$g_fmax" 'BEGIN { print (s > 0 && g > 0) ? 1 : 0 }')
    [[ "$fmax_valid" -eq 0 ]] && { echo "0/1"; return; }

    # Check Fmax: should be >= golden * 0.9
    local ok=$(awk -v s="$s_fmax" -v g="$g_fmax" 'BEGIN { print (s >= g * 0.9) ? 1 : 0 }')

    echo "$ok/1"
}

# Main grading loop
designs=(naive clever)
echo ""
echo "Design                 Student(M,Fmax,ALMs)  Golden(M,Fmax,ALMs)   Score  Functionality"
echo "============================================================================================"
total_score=0
total_possible=0

for design in "${designs[@]}"; do
    dut="${design}adder2048b"

    # Get functionality score for this design
    func_pass=${dut_pass[$dut]:-0}
    func_total=1
    func_str="$func_pass/$func_total"

    student="results/winner_${design}.csv"
    golden="results/gold.winner_${design}.csv"

    # Get M, Fmax, ALMs from both files for display
    s_vals=$(sed -n '2p' "$student" 2>/dev/null | cut -d',' -f1-3)
    g_vals=$(sed -n '2p' "$golden" 2>/dev/null | cut -d',' -f1-3)

    # Replace empty values with "MISSING" for display
    [[ -z "$s_vals" ]] && s_vals="MISSING"
    [[ -z "$g_vals" ]] && g_vals="MISSING"

    # Zero out benchmark score if functionality is 0
    if [[ "$func_pass" -eq 0 ]]; then
        result="0/1"
        points=0
    else
        result=$(compare_winner "$student" "$golden")
        points=$(echo "$result" | cut -d'/' -f1)
    fi

    printf "%-22s %-21s %-21s %-6s %s\n" \
        "${design}" "$s_vals" "$g_vals" "$result" "$func_str"

    ((total_score += points))
    ((total_possible += 1))
done

echo "============================================================================================"
printf "Total: %d/%d\n" $total_score $total_possible
