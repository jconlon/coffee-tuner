# Import the newest Beanconqueror export from ~/Downloads (sent from the tablet via KDE Connect).
#
# A full export on the tablet writes Beanconqueror.zip (JSON only) plus a loose brews/ folder with
# flow profiles next to it. Send both: the zip, and the brews folder compressed (e.g. brews.zip).
# Any brews*.zip sent after the chosen Beanconqueror zip is merged into the same import.
use lib.nu *

def newest [pattern: string] {
    glob $pattern | each {|f| ls $f | first } | sort-by modified --reverse
}

def main [--dir: path = "~/Downloads", --no-parse] {
    let dl = ($dir | path expand)
    let found = (newest ($dl | path join "Beanconqueror*.zip"))
    if ($found | is-empty) { error make {msg: $"no Beanconqueror*.zip in ($dl) — share an export from the tablet via KDE Connect"} }
    let pick = ($found | first)
    let dest = (ingest $pick.name --label inbox)
    print $"Imported ($pick.name) \(($pick.modified | format date '%Y-%m-%d %H:%M')\) → ($dest)"

    let flows = (newest ($dl | path join "brews*.zip") | where modified >= $pick.modified)
    if ($flows | is-empty) {
        print "Note: no brews*.zip newer than this export, so no flow profiles (send the export's brews folder, compressed)"
    } else {
        let fz = ($flows | first)
        cp $fz.name $dest
        ^unzip -q -o $fz.name -d $dest
        print $"Merged flow profiles from ($fz.name)"
    }
    if not $no_parse {
        ^nu (root | path join "scripts" "parse.nu")
        if not (glob $"($dest)/**/brews/*_flow_profile.json" | is-empty) { ^nu (root | path join "scripts" "flows.nu") }
    }
}
