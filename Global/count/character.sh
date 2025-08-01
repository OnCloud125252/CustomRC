#!/bin/bash

# Check if a directory argument was provided
if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

# Set the directory to search
directory="$1"

# List of file names to ignore
ignore_files=(
  "bun.lockb"
  "count_words.sh"
  "nest-cli.json"
  "nixpacks.toml"
  "package.json"
  "pnpm-lock.yaml"
  "tsconfig.build.json"
  "tsconfig.json"
)

# List of directories to ignore
ignore_dirs=(
  ".git"
  "node_modules"
  "dist"
)

# Total character count
total_characters=0

# Function to count characters in a file, excluding whitespace and newlines
count_characters() {
    local file="$1"
    local char_count=$(tr -d '[:space:][:cntrl:]' < "$file" | wc -c)
    echo "$file: $char_count characters"
    total_characters=$((total_characters + char_count))
}

# Recursive function to search directories
search_directory() {
    local dir="$1"
    for item in "$dir"/*
    do
        local base_name=$(basename "$item")
        if [ -d "$item" ]; then
            if [[ ! " ${ignore_dirs[*]} " =~ " ${base_name} " ]]; then
                search_directory "$item"
            fi
        elif [ -f "$item" ]; then
            if [[ ! " ${ignore_files[*]} " =~ " ${base_name} " ]]; then
                count_characters "$item"
            fi
        fi
    done
}

# Call the recursive search function
search_directory "$directory"

# Display the total character count
echo "Total characters (excluding whitespace and newlines): $total_characters"