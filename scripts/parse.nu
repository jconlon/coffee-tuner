# Flatten a Beanconqueror export into CSV tables.
# Export zips contain Beanconqueror.json plus chunk files Beanconqueror_Brews_N.json / Beanconqueror_Beans_N.json;
# chunks are merged with the main file. Field names follow the Beanconqueror data model; missing fields
# come through as empty rather than failing.
use lib.nu *

# ISO roast date (e.g. 2026-11-12T19:54:38.618Z) -> local YYYY-MM-DD
def day [v] { if ($v | is-empty) { null } else { $v | into datetime | date to-timezone local | format date "%Y-%m-%d" } }

# Trimmed text, or null when empty (names/roasters sometimes carry stray spaces)
def clean [v] { if ($v | is-empty) { null } else { $v | into string | str trim } }

def ts [v] { if ($v | is-empty) { null } else { $v * 1_000_000_000 | into datetime | date to-timezone local | format date "%Y-%m-%d %H:%M" } }

# Records from the main JSON key plus all matching chunk files, de-duplicated by uuid
def collect [dir: path, main: record, key: string, chunk: string] {
    let from_main = ($main | get -o $key | default [])
    let from_chunks = (glob $"($dir)/**/Beanconqueror_($chunk)_*.json" | sort | each {|f| open $f } | flatten)
    $from_main | append $from_chunks | each {|r| $r | insert _id ($r | get -o config.uuid) } | uniq-by _id | reject _id
}

def main [] {
    let dir = (latest-import)
    let mains = (glob $"($dir)/**/Beanconqueror.json")
    if ($mains | is-empty) { error make {msg: $"no Beanconqueror.json in ($dir)"} }
    print $"Parsing ($dir)"
    let data = (open ($mains | first))
    let beans = (collect $dir $data BEANS Beans)
    let brews = (collect $dir $data BREWS Brews)

    # Each BEANS entry is one bag (roast batch). `coffee` is the trimmed name: bags of the same coffee share it.
    let bean_rows = ($beans | each {|b| {
        uuid: $b.config.uuid
        name: $b.name
        coffee: (clean $b.name)
        roaster: (clean ($b | get -o roaster))
        roast_date: (day ($b | get -o roastingDate))
        roast: ($b | get -o roast)
        weight: ($b | get -o weight)
        finished: ($b | get -o finished)
    }})

    let bags = ($bean_rows | reduce -f {} {|b, acc| $acc | upsert $b.uuid $b })

    let brew_rows = ($brews | each {|r|
        let bean_id = ($r | get -o bean)
        let bag = (if ($bean_id | is-empty) { null } else { $bags | get -o $bean_id })
        let time = (ts ($r.config | get -o unix_timestamp))
        let roast_date = ($bag | get -o roast_date)
        {
            uuid: ($r.config | get -o uuid)
            time: $time
            bean: ($bag | get -o name)
            coffee: ($bag | get -o coffee)
            roaster: ($bag | get -o roaster)
            bean_uuid: $bean_id
            roast_date: $roast_date
            days_off_roast: (if ($roast_date | is-empty) or ($time | is-empty) { null } else {
                (($time | str substring 0..9 | into datetime) - ($roast_date | into datetime)) / 1day | math floor
            })
            grind: ($r | get -o grind_size)
            dose_g: ($r | get -o grind_weight)
            yield_g: ($r | get -o brew_beverage_quantity)
            water_g: ($r | get -o brew_quantity)
            time_s: ($r | get -o brew_time)
            temp_c: ($r | get -o brew_temperature)
            rating: ($r | get -o rating)
            flow_profile: ($r | get -o flow_profile)
            note: ($r | get -o note)
        }
    } | insert ratio {|r|
        if ($r.dose_g | default 0) > 0 and ($r.yield_g | default 0) > 0 { ($r.yield_g / $r.dose_g) | math round -p 2 } else { null }
    } | sort-by time)

    let out = (root | path join "data" "derived")
    $bean_rows | to csv | save -f ($out | path join "beans.csv")
    $brew_rows | to csv | save -f ($out | path join "brews.csv")
    print $"($bean_rows | length) beans, ($brew_rows | length) brews -> ($out)"
}
