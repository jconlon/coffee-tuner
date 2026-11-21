# Import a Beanconqueror export into data/raw/<timestamp>/
def main [file: path] {
    let src = ($file | path expand)
    if not ($src | path exists) { error make {msg: $"not found: ($src)"} }
    let stamp = (date now | format date "%Y%m%d-%H%M%S")
    let dest = ($env.FILE_PWD | path dirname | path join "data" "raw" $stamp)
    mkdir $dest
    if ($src | str ends-with ".zip") {
        ^unzip -q $src -d $dest
    } else {
        cp $src $dest
    }
    print $"Imported to ($dest)"
    ls $dest | select name size
}
