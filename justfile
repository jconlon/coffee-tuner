# coffee-tuner tasks — scripts live in scripts/ and are written in nushell

set shell := ["nu", "-c"]

# List available tasks
default:
    @just --list

# Pair with tablet Wireless debugging (Developer options → Wireless debugging → Pair device with pairing code)
tablet-pair addr code:
    nu scripts/tablet.nu pair '{{addr}}' '{{code}}'

# Connect to tablet over Wireless debugging (ip:port from that screen) and remember it in .tablet
tablet-connect addr:
    nu scripts/tablet.nu connect '{{addr}}'

# Show connected tablet, Android version, and whether Beanconqueror is installed
tablet-status:
    nu scripts/tablet.nu status

# List Beanconqueror export zips found on the tablet
tablet-list:
    nu scripts/tablet.nu list

# Pull newest export from tablet into data/raw and parse it (prefers full export; `just pull --auto` for newest auto backup)
pull *flags:
    nu scripts/tablet.nu pull {{flags}}

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
