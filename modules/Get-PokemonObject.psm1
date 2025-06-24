function Get-PokemonObject {
    <#
    .SYNOPSIS
        Creates a new Pokemon object with the given name.
    #>
    param (
        [string]$name
    )
    $pkmn = @{
        name = $name.Trim().Replace("’","'")
        evo = @()
        newEvo = @()
        move = @{
            lv = @()
            other = @()
        }
    }
    return $pkmn
}