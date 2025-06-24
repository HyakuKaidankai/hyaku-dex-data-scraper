$pkmns = Get-Content -Path  "H:\Dev\AstroDevContainer\astro-dex\src\assets\data\pokemons.json" -Raw | ConvertFrom-Json -Depth 100
$alts = Get-Content -Path  "H:\Dev\AstroDevContainer\astro-dex\src\assets\data\alt_names.json" -Raw | ConvertFrom-Json


$total_counter = 0
$match_counter = 0

foreach($pkmn in $pkmns) {
    $pkmnName = $pkmn.'Species Name'
    $total_counter++
    foreach ($alt in $alts) {
        if ($alt.'Canonical Name'.toLower() -eq $pkmnName.toLower()) {
            $pkmn | Add-Member -NotePropertyName display_name -NotePropertyValue $alt.'Readable Name' -Force
            $match_counter++
        }
    }
}

Write-Host ("Total Pokemon: " + $total_counter)
Write-Host ("Pokemon with abilities: " + $match_counter)

$pkmns | ConvertTo-Json -Depth 100 | Out-File -FilePath "H:\Dev\AstroDevContainer\astro-dex\src\assets\data\pokemons.json"