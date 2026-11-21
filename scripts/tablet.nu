# Drive Beanconqueror data transfer from the Android tablet over adb.
#
# Exports Beanconqueror writes on Android:
#   - automatic daily backups (JSON only, no flow profiles/images, 7 days kept):
#       /sdcard/Android/data/com.beanconqueror.app/files/Download/Beanconqueror_export/Beanconqueror_automatic_export_DD_MM_YYYY.zip
#   - manual "Full export to directory" (includes flows/images): Beanconqueror.zip in a folder you pick;
#       pick Download or Documents so `pull` can find it.
use lib.nu *

const PKG = "com.beanconqueror.app"
const SEARCH_DIRS = [
    "/sdcard/Download"
    "/sdcard/Documents"
    "/sdcard/Android/data/com.beanconqueror.app/files/Download/Beanconqueror_export"
]

def state-file [] { root | path join ".tablet" }

# Saved tablet address (ip:port), if any
def saved-addr [] {
    let f = (state-file)
    if ($f | path exists) { open $f | str trim } else { "" }
}

# adb with the saved tablet as target (falls back to the only attached device)
def --wrapped tadb [...args] {
    let addr = (saved-addr)
    if $addr != "" and ($addr in (devices | get serial)) {
        ^adb -s $addr ...$args
    } else {
        ^adb ...$args
    }
}

def devices [] {
    ^adb devices | lines | skip 1 | where $it != "" | parse "{serial}\t{state}"
}

def require-device [] {
    let ds = (devices | where state == device)
    if ($ds | is-empty) {
        error make {msg: "no tablet connected — run `just tablet-connect <ip:port>` (wireless) or plug in USB with USB debugging on"}
    }
}

# Find Beanconqueror zips on the tablet: newest first
def remote-exports [] {
    let dirs = ($SEARCH_DIRS | str join " ")
    let cmd = $"for d in ($dirs); do [ -d \"$d\" ] && find \"$d\" -maxdepth 2 -name 'Beanconqueror*.zip' -exec stat -c '%Y|%s|%n' {} + ; done 2>/dev/null"
    tadb shell $cmd
    | lines | where $it != ""
    | parse "{mtime}|{size}|{path}"
    | update mtime {|r| ($r.mtime | into int) * 1_000_000_000 | into datetime }
    | update size {|r| $r.size | into filesize }
    | insert kind {|r| if ($r.path | str contains "automatic_export") { "auto (no flows)" } else { "full" } }
    | sort-by mtime --reverse
}

def main [] { help main }

# Pair with the tablet's Wireless debugging (Developer options → Wireless debugging → Pair device with pairing code)
def "main pair" [addr: string, code: string] {
    ^adb pair $addr $code
}

# Connect over Wireless debugging (ip:port shown on the Wireless debugging screen) and remember it
def "main connect" [addr: string] {
    ^adb connect $addr
    $addr | save -f (state-file)
    print $"Saved tablet address to (state-file)"
}

# Show adb devices and whether Beanconqueror is installed
def "main status" [] {
    print $"Saved address: (saved-addr | default '(none)')"
    print (devices)
    require-device
    let model = (tadb shell getprop ro.product.model | str trim)
    let android = (tadb shell getprop ro.build.version.release | str trim)
    let installed = (tadb shell pm list packages $PKG | str contains $PKG)
    print $"Tablet: ($model), Android ($android), Beanconqueror installed: ($installed)"
}

# List Beanconqueror exports found on the tablet
def "main list" [] {
    require-device
    let found = (remote-exports)
    if ($found | is-empty) { print "No Beanconqueror*.zip found in: " ; print $SEARCH_DIRS } else { $found }
}

# Pull the newest export (prefers a full export unless --auto) into data/raw/, then parse it
def "main pull" [
    --auto            # take the newest automatic backup even if a full export exists
    --no-parse        # skip `parse` after pulling
] {
    require-device
    let found = (remote-exports)
    if ($found | is-empty) {
        error make {msg: "no exports on tablet — in Beanconqueror: Settings → Full export to directory → choose Download"}
    }
    let full = ($found | where kind == full)
    let pick = if (not $auto) and (not ($full | is-empty)) { $full | first } else { $found | first }
    let newest = ($found | first)
    if $pick.path != $newest.path {
        print $"Note: newer automatic backup exists \(($newest.mtime)\) — using full export from ($pick.mtime) for flow data. Use --auto to take the newest."
    }
    let tmp = (mktemp -d)
    let local = ($tmp | path join ($pick.path | path basename))
    tadb pull $pick.path $local
    let dest = (ingest $local --label (if $pick.kind == full { "full" } else { "auto" }))
    rm -rf $tmp
    print $"Pulled ($pick.path) \(($pick.kind), ($pick.mtime)\) → ($dest)"
    if not $no_parse { ^nu (root | path join "scripts" "parse.nu") }
}
