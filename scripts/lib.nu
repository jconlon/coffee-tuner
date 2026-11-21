# Shared helpers

export def root [] { $env.FILE_PWD | path dirname }

# Path to the main JSON in the newest raw import
export def latest-export [] {
    let raw = (root | path join "data" "raw")
    let dirs = (ls $raw | where type == dir | sort-by name)
    if ($dirs | is-empty) { error make {msg: "no imports in data/raw — run `just import <file>`"} }
    let dir = ($dirs | last | get name)
    let jsons = (glob $"($dir)/**/*.json" | where {|f| ($f | path basename) =~ '(?i)beanconqueror' })
    let jsons = if ($jsons | is-empty) { glob $"($dir)/**/*.json" } else { $jsons }
    if ($jsons | is-empty) { error make {msg: $"no JSON found in ($dir)"} }
    $jsons | first
}
