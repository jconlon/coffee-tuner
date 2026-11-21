# Flatten a Beanconqueror backup into CSV tables.
# Field names are based on the Beanconqueror backup format (BEANS / BREWS / MILL / PREPARATION);
# missing fields come through as empty rather than failing.
use lib.nu *

def ts [v] { if ($v | is-empty) { null } else { $v * 1_000_000_000 | into datetime } }

def main [] {
    let src = (latest-export)
    print $"Parsing ($src)"
    let data = (open $src)
    let beans = ($data | get -o BEANS | default [])
    let mills = ($data | get -o MILL | default [])
    let preps = ($data | get -o PREPARATION | default [])
    let brews = ($data | get -o BREWS | default [])

    let bean_names = ($beans | each {|b| {k: $b.config.uuid, v: $b.name} } | transpose -r -d)
    let lookup = {|tbl, id| if ($id | is-empty) { null } else { $tbl | get -o $id } }

    let bean_rows = ($beans | each {|b| {
        uuid: $b.config.uuid
        name: $b.name
        roaster: ($b | get -o roaster)
        roast_date: ($b | get -o roastingDate)
        roast: ($b | get -o roast)
        weight: ($b | get -o weight)
        finished: ($b | get -o finished)
    }})

    let brew_rows = ($brews | each {|r| {
        time: (ts ($r.config | get -o unix_timestamp))
        bean: (do $lookup $bean_names ($r | get -o bean))
        grind: ($r | get -o grind_size)
        dose_g: ($r | get -o grind_weight)
        yield_g: ($r | get -o brew_beverage_quantity)
        water_g: ($r | get -o brew_quantity)
        time_s: ($r | get -o brew_time)
        temp_c: ($r | get -o brew_temperature)
        rating: ($r | get -o rating)
        note: ($r | get -o note)
    }} | upsert ratio {|r|
        if ($r.dose_g | default 0) > 0 and ($r.yield_g | default 0) > 0 { ($r.yield_g / $r.dose_g) | math round -p 2 } else { null }
    } | sort-by time)

    let out = (root | path join "data" "derived")
    $bean_rows | to csv | save -f ($out | path join "beans.csv")
    $brew_rows | to csv | save -f ($out | path join "brews.csv")
    print $"($bean_rows | length) beans, ($brew_rows | length) brews -> ($out)"
}
