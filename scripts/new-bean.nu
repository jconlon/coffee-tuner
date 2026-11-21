# Create beans/<slug>.md from a template
use lib.nu *

def main [name: string] {
    let slug = ($name | str lowercase | str replace -ra '[^a-z0-9]+' '-' | str trim -c '-')
    let f = (root | path join "beans" $"($slug).md")
    if ($f | path exists) { error make {msg: $"already exists: ($f)"} }
    $"# ($name)

- **Roaster:**
- **Origin / process:**
- **Roast level:**
- **Roast date:**
- **Opened:**

## Best recipe so far
| Dose | Yield | Ratio | Grind \(DF64\) | Time | Temp | Pre-infusion | Basket |
|------|-------|-------|--------------|------|------|--------------|--------|
|      |       |       |              |      |      |              |        |

Tasting notes:

## Dial-in history
| Date | Grind | Dose | Yield | Time | Temp | Taste | Next change |
|------|-------|------|-------|------|------|-------|-------------|
" | save $f
    print $"Created ($f)"
}
