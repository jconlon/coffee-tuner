# Shared helpers

export def root [] { $env.FILE_PWD | path dirname }

# Copy a local export (.zip or .json) into data/raw/<timestamp>/, unzipping zips. Returns the folder.
export def ingest [src: path, --label: string = ""] {
    let stamp = (date now | format date "%Y%m%d-%H%M%S")
    let name = if $label == "" { $stamp } else { $"($stamp)-($label)" }
    let dest = (root | path join "data" "raw" $name)
    mkdir $dest
    if ($src | str ends-with ".zip") {
        cp $src $dest
        ^unzip -q -o $src -d $dest
    } else {
        cp $src $dest
    }
    $dest
}

# Folder of the newest import in data/raw
export def latest-import [] {
    let raw = (root | path join "data" "raw")
    let dirs = (ls $raw | where type == dir | sort-by name)
    if ($dirs | is-empty) { error make {msg: "no imports in data/raw — run `just inbox` or `just import <file>`"} }
    $dirs | last | get name
}
