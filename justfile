# coffee-tuner tasks — scripts live in scripts/ and are written in nushell

set shell := ["nu", "-c"]

# List available tasks
default:
    @just --list

# Copy a Beanconqueror export (.zip or .json) into data/raw with a timestamp, unzipping if needed
import file:
    nu scripts/import.nu '{{file}}'

# Flatten the latest raw export into data/derived/{beans,brews}.csv
parse:
    nu scripts/parse.nu

# Show recent brews (optionally filter by bean name substring)
brews bean="" n="20":
    nu scripts/brews.nu --bean '{{bean}}' --n {{n}}

# Create a new bean notes file from the template
new-bean name:
    nu scripts/new-bean.nu '{{name}}'

# List bean notes files
beans:
    ls beans | where name =~ '\.md$' | select name modified
