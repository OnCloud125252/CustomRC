#!/bin/zsh

# Get the absolute path to the repo root
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
GLOBAL_DIR="$REPO_ROOT/rc-modules/Global"
DARWIN_DIR="$REPO_ROOT/rc-modules/Darwin"
CONFIGS_FILE="$REPO_ROOT/configs.sh"
MONOLITHIC_FILE="$REPO_ROOT/tests/monolithic_rc.sh"

# Colors for output
GREEN=$'\e[0;32m'
BLUE=$'\e[0;34m'
NC=$'\e[0m' # No Color

echo "${BLUE}=== RC Benchmark Tool ===${NC}"

# 1. Source configs to get ignore lists
if [ -f "$CONFIGS_FILE" ]; then
    source "$CONFIGS_FILE"
else
    echo "Error: configs.sh not found at $CONFIGS_FILE"
    exit 1
fi

# Function to check if a file is in an ignore list
is_ignored() {
    local filename="$1"
    shift
    local list=("$@")

    if [[ ${list[(Ie)$filename]} -ne 0 ]]; then
        return 0
    fi
    return 1
}

# 2. Generate the monolithic file
echo "\n${BLUE}[1/3] Generating monolithic file...${NC}"
echo "# Monolithic RC generated on $(date)" > "$MONOLITHIC_FILE"

# Helper to process a directory
process_dir() {
    local dir="$1"
    local name="$2"
    shift 2
    local -a ignore_list
    ignore_list=("$@")

    echo "Processing $name modules..."

    if [ -d "$dir" ]; then
        for filepath in "$dir"/*.sh; do
            [ -e "$filepath" ] || continue
            filename=$(basename "$filepath")

            if is_ignored "$filename" "${ignore_list[@]}"; then
                echo "  Skipping ignored: $filename"
            else
                echo "# === $filename ===" >> "$MONOLITHIC_FILE"
                cat "$filepath" >> "$MONOLITHIC_FILE"
                echo "\n" >> "$MONOLITHIC_FILE"
            fi
        done
    else
        echo "Warning: Directory $dir not found"
    fi
}

process_dir "$GLOBAL_DIR" "Global" "${CUSTOMRC_GLOBAL_IGNORE_LIST[@]}"
process_dir "$DARWIN_DIR" "Darwin" "${CUSTOMRC_DARWIN_IGNORE_LIST[@]}"

echo "Monolithic file created at: $MONOLITHIC_FILE"
echo "Size: $(wc -l < "$MONOLITHIC_FILE") lines"

# 3. Benchmark
echo "\n${BLUE}[2/3] Benchmarking original customrc.sh...${NC}"
# Use a subshell to avoid polluting this shell and ensuring correct relative paths
# We invoke zsh explicitly to ensure we're measuring startup time including parsing
START_TIME=$(date +%s%N)
(cd "$REPO_ROOT" && zsh -c "source ./customrc.sh" > /dev/null 2>&1)
END_TIME=$(date +%s%N)
DURATION_ORIG=$(( (END_TIME - START_TIME) / 1000000 ))
echo "${GREEN}Original customrc took: ${DURATION_ORIG}ms${NC}"

echo "\n${BLUE}[3/3] Benchmarking monolithic file...${NC}"
START_TIME=$(date +%s%N)
(cd "$REPO_ROOT" && zsh -c "source $MONOLITHIC_FILE" > /dev/null 2>&1)
END_TIME=$(date +%s%N)
DURATION_MONO=$(( (END_TIME - START_TIME) / 1000000 ))
echo "${GREEN}Monolithic file took:   ${DURATION_MONO}ms${NC}"

# Summary
echo "\n${BLUE}=== Summary ===${NC}"
DIFF=$((DURATION_ORIG - DURATION_MONO))
if [ $DIFF -gt 0 ]; then
    echo "Monolithic is faster by ${GREEN}${DIFF}ms${NC}"
else
    DIFF=$((DURATION_MONO - DURATION_ORIG))
    echo "Original is faster by ${GREEN}${DIFF}ms${NC}"
fi
