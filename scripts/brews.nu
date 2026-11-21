# Show recent brews from data/derived/brews.csv
use lib.nu *

def main [--bean: string = "", --n: int = 20] {
    let f = (root | path join "data" "derived" "brews.csv")
    if not ($f | path exists) { error make {msg: "no brews.csv — run `just parse`"} }
    open $f
    | where {|r| $bean == "" or (($r.bean | default "" | str lowercase) | str contains ($bean | str lowercase)) }
    | last $n
}
