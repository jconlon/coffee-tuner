# coffee-tuner tasks — scripts live in scripts/ and are written in nushell

set shell := ["nu", "-c"]

# List available tasks
default:
    @just --list

# Import newest Beanconqueror*.zip (+ brews*.zip flow profiles) from ~/Downloads (sent via KDE Connect) and parse it
inbox *flags:
    nu scripts/inbox.nu {{flags}}

# Copy a Beanconqueror export (.zip or .json) already on this computer into data/raw, unzipping if needed
import file:
    nu scripts/import.nu '{{file}}'

# Flatten the latest raw export into data/derived/{beans,brews}.csv
parse:
    nu scripts/parse.nu

# Summarize scale flow profiles into data/derived/shots.csv (one row per shot, joined to brews)
flows:
    nu scripts/flows.nu

# Show recent brews (optionally filter by bean name substring)
brews bean="" n="20":
    nu scripts/brews.nu --bean '{{bean}}' --n {{n}}

# Create a new bean notes file from the template
new-bean name:
    nu scripts/new-bean.nu '{{name}}'

# List bean notes files
beans:
    ls beans | where name =~ '\.md$' | select name modified
