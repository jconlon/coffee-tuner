# Summarize Beanconqueror scale flow profiles (brews/<uuid>_flow_profile.json) into data/derived/shots.csv,
# one row per brew with flow metrics joined to brews.csv.
#
# Flow profile files hold scale data only (weight + flow over time); pressure/temperature are empty
# because the Apex V2 does not report to Beanconqueror.
use lib.nu *

# Metrics for one flow profile
def metrics [f: path] {
    let p = (open $f)
    let w = ($p | get -o weight | default []
        | each {|r| {t: ($r.brew_time | into float), w: ($r | get -o actual_smoothed_weight | default $r.actual_weight)} }
        | where t >= 0)
    if ($w | length) < 10 { return null }
    let final = ($w | get w | math max)
    if $final < 5 { return null }
    let at = {|frac| $w | where w >= ($final * $frac) | first | get t }
    let t_drip = ($w | where w >= 1.0 | first | get t)
    let t20 = (do $at 0.2)
    let t80 = (do $at 0.8)
    let t95 = (do $at 0.95)
    let main_rate = if $t80 > $t20 { ($final * 0.6) / ($t80 - $t20) } else { null }

    let flow = ($p | get -o realtimeFlow | default []
        | each {|r| {t: ($r.brew_time | into float), v: ($r | get -o flow_value)} }
        | where {|r| $r.v != null and $r.t >= $t20 and $r.t <= $t80 })
    let fv = ($flow | get -o v | default [])
    let mean = if ($fv | is-empty) { null } else { $fv | math avg }
    let sd = if ($fv | length) < 3 { null } else { $fv | math stddev }
    # spikes: flow readings > 2x the main-phase mean (gushes / channeling)
    let spikes = if $mean == null or $mean <= 0 { null } else { $fv | where $it > ($mean * 2) | length }
    {
        uuid: ($f | path basename | str replace '_flow_profile.json' '')
        scale_final_g: ($final | math round -p 1)
        scale_time_s: ($w | last | get t)
        t_first_drip_s: $t_drip
        t_to_95pct_s: $t95
        preinfusion_gap_s: ($t20 - $t_drip | math round -p 1)
        main_flow_gps: (if $main_rate == null { null } else { $main_rate | math round -p 2 })
        flow_peak_gps: (if ($fv | is-empty) { null } else { $fv | math max | math round -p 2 })
        flow_cv: (if $sd == null or $mean == null or $mean <= 0 { null } else { $sd / $mean | math round -p 2 })
        flow_spikes: $spikes
    }
}

def main [] {
    let dir = (latest-import)
    let files = (glob $"($dir)/**/brews/*_flow_profile.json")
    if ($files | is-empty) { error make {msg: $"no flow profiles under ($dir)/brews — send the export's brews folder too"} }
    let out = (root | path join "data" "derived")
    let brews = (open ($out | path join "brews.csv"))
    let m = ($files | par-each {|f| metrics $f } | compact)
    let shots = ($brews | join $m uuid | sort-by time)
    $shots | to csv | save -f ($out | path join "shots.csv")
    print $"($files | length) flow files, ($m | length) usable, ($shots | length) joined to brews -> ($out)/shots.csv"
}
