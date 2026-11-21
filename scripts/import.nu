# Import a Beanconqueror export file already on this computer
use lib.nu *

def main [file: path] {
    let src = ($file | path expand)
    if not ($src | path exists) { error make {msg: $"not found: ($src)"} }
    let dest = (ingest $src --label manual)
    print $"Imported to ($dest)"
    ls $dest | select name size
}
