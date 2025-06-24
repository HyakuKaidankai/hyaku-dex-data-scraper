$replacementTuples = @(
    @{ old="Bloodmoon Ursaluna"; new="Ursaluna (Bloodmoon)"}
    @{ old="Palafin"; new="Palafin Zero Form" }
    @{ old="Deoxys"; new="Deoxys Normal Forme" }
    @{ old="Lycanroc (Midday)"; new="LYCANROC Midday" }
    @{ old="Lycanroc (Midnight)"; new="LYCANROC Midnight" }
    @{ old="Lycanroc (Dusk)"; new="LYCANROC Dusk" }
    @{ old="Basculegion (Female)"; new="Basculegion Female" }
    @{ old="Basculegion (Male)"; new="Basculegion Male" }
    @{ old="Urshifu (S)"; new="URSHIFU Single Strike Form" }
    @{ old="Urshifu (R)"; new="URSHIFU Rapid Strike Form" }
    
)

$useSelfNameTuples = @(
    "Rotom Normal Form",
    "EISCUE Ice Face",
    "EISCUE Noice Face",
    "ENAMORUS Incarnate Forme",
    "ENAMORUS Therian Forme",
    "THUNDURUS Incarnate Forme",
    "THUNDURUS Therian Forme",
    "Landorus Incarnate Forme",
    "Landorus Therian Forme",
    "TORNADUS Incarnate Forme",
    "TORNADUS Therian Forme",
    "INDEEDEE Male",
    "INDEEDEE Female",
    "WISHIWASHI Solo",
    "WISHIWASHI Schooling",
    "ZAMAZENTA Hero of Many Battles Forme",
    "ZAMAZENTA Crowned Shield Forme",
    "ZACIAN Hero of Many Battles Forme",
    "ZACIAN Crowned Sword Forme",
    "HOOPA Confined",
    "HOOPA Unbound",
    "ZYGARDE 10% Forme",
    "ZYGARDE 50% Forme",
    "ZYGARDE Complete Forme",
    "GIRATINA Origin Forme",
    "GIRATINA Altered Forme",
    "Shaymin Sky Forme",
    "Shaymin Land Forme",
    "MINIOR Meteor",
    "MINIOR Core",
    "KYUREM Normal Forme",
    "KYUREM Black Fusion Forme",
    "KYUREM White Fusion Forme",
    "MELOETTA Aria Forme",
    "MELOETTA Pirouette Forme",
    "MELOETTA Step Forme"
)

function Test-PokemonName {
    param(
        $dex,
        $str
    )
    foreach($pkmn in $dex) {
        if($pkmn.name.ToLower() -eq $str.ToLower()) {
            return $true
        }
    }
    return $false
}

function Convert-EvoLines {
    <#
    .SYNOPSIS
        Converts the Evolution lines of a Pokemon, from the original string list to a list of parsed objects.
    #>
    param(
        $dex
    )
    $newDex = @()

    Write-Host "Evolution conversion started"
    foreach ($pkmn in $dex) {
        foreach($line in $pkmn.evo) {
            $level_before_minimum = $false
            $add_level = $false

            # Separate the index from the rest of the line
            $splitted = $line.split("-")             
            $rest_of_line = ($splitted[1..($splitted.length - 1)] -join "-").Trim()   
            
            # Case - Sex variant pokemon - Needs to go before "minimum" case, as it also applies to it, after the removal
            $ends_in_male = $rest_of_line.ToLower().EndsWith("male")
            if($ends_in_male) {
                $rest_of_line = (($rest_of_line.Split()[0..($rest_of_line.Split().Length - 2)]) -join ' ').Trim()
            }

            # Case - Ends with "Minimum" and has a number before it
            $ends_in_minimum = $rest_of_line.ToLower().EndsWith("minimum")
            if($ends_in_minimum) {
                $level_before_minimum = ($rest_of_line.Split()[-2] -match '^\d+$')       
                if($level_before_minimum) {
                    $level = $rest_of_line.Split()[-2] 
                    $removal_idx = $rest_of_line.Split()[-3].toLower().EndsWith("lv") ? 4 : 3
                    $rest_of_line = (($rest_of_line.Split()[0..($rest_of_line.Split().Length - $removal_idx)]) -join ' ').Trim()
                    $add_level = $true
                }         
            }

            # Case - Ends with "Minimum <level>"
            $ends_in_number = ($rest_of_line.Split()[-1] -match '^\d+$')
            if($ends_in_number) {
                $minimum_before_level = $rest_of_line.Split()[-2].toLower().EndsWith("minimum")
                if($minimum_before_level) {
                    $level = $rest_of_line.Split()[-1]
                    $rest_of_line = (($rest_of_line.Split()[0..($rest_of_line.Split().Length - 3)]) -join ' ').Trim()
                    $add_level = $true
                }
            }

            # Case - Regional variant pokemon
            $ends_in_alolan = $rest_of_line.ToLower().EndsWith("(a)")
            if($ends_in_alolan) {
                $rest_of_line = $rest_of_line.replace("(A)", "Alola")
            }
            $ends_in_galarian = $rest_of_line.ToLower().EndsWith("(g)")
            if($ends_in_galarian) {
                $rest_of_line = $rest_of_line.replace("(G)", "Galar")
            }            
            $ends_in_hisuian = $rest_of_line.ToLower().EndsWith("(h)")
            if($ends_in_hisuian) {
                $rest_of_line = $rest_of_line.replace("(H)", "Hisuian")
            }            

            # Case - Direct replacement
            foreach($tuple in $replacementTuples) {
                if($rest_of_line.ToLower() -eq $tuple.old.ToLower()) {
                    $rest_of_line = $tuple.new
                }
            }

            # Case - Replace with the name of pokemon itself
            foreach($tuple in $useSelfNameTuples) {
                if($pkmn.name -eq $tuple.ToLower()) {
                    $rest_of_line = $pkmn.name
                }
            }

            # Create the object
            $aux_evo_line = @{
                # idx = $splitted[0].Trim()
                name = $rest_of_line
            }
            if($add_level) {
                $aux_evo_line.level = $level
            }            

            # Almost always this matches with 1 of the list of evolutions - itself
            $is_itself = $rest_of_line.ToLower() -eq $pkmn.name.ToLower()
            $is_another_pokemon = Test-PokemonName -dex $dex -str $rest_of_line
            if($is_itself -or $is_another_pokemon ) {
                $pkmn.newEvo += $aux_evo_line
            } else {
                write-host ($aux_evo_line | ConvertTo-Json -Depth 100 -Compress)
            }            
        }
    }

    # Remove the original 'evo' property from each pokemon in the dex
    foreach ($pkmn in $dex) {        
        $obj = $pkmn | Select-Object -Property * -ExcludeProperty evo
        $obj | Add-Member -MemberType NoteProperty -Name "evo" -Value $pkmn.newEvo 
        $newDex += ($obj | Select-Object -Property * -ExcludeProperty newEvo)
    }

    Write-Host "Evolution conversion finished"
    return $newDex 
}

Export-ModuleMember -Function Convert-EvoLines