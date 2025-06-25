# Requires -Version 7.0

param(
    [Parameter(Mandatory = $false)]
    [string] $config = ".\config.json"
)

# Load configuration
$conf = Get-Content -Path $config -Raw | ConvertFrom-Json -Depth 10
$dexFiles = $conf.dex_files
$logEnabled = $conf.log_enabled
$logFile = $conf.log_filename
if ($logEnabled) {
    Remove-Item -Path $logFile -ErrorAction SilentlyContinue
}

# Import auxiliary modules
Import-Module .\modules\Get-PokemonObject.psm1 -Force
Import-Module .\modules\Write-Log.psm1 -Force
Import-Module .\modules\Convert-OtherMoves.psm1 -Force
Import-Module .\modules\Write-DexFiles.psm1 -Force
Import-Module .\modules\Convert-EvoLines.psm1 -Force

# -----------------

# Result object with all the info
$dex = @()

# Pivot object for saving info across loops
$aux_pkmn = Get-PokemonObject "Auxiliary Pokemon"

# Process each dex file
foreach($dexFile in $dexFiles) {
    Write-Host ("- Processing file " + $dexFile.path)
    Write-Log -Enabled $LogEnabled -LogFile $LogFile -Msg ("File " + $dexFile.path)
    $dexContent = Get-Content -Path  $dexFile.path -Raw    
    $state = "UNINITIALIZED"

    foreach ($line in ($dexContent -split "`r`n") ) {

        #Enable Debug for a specific pokemon
        # if ($aux_pkmn.name.Contains("Venusaur") ) {
        #     $DebugPreference = 'Continue' 
        # } else {
        #     $DebugPreference = 'SilentlyContinue' 
        # }
        # Write-Log -Enabled $LogEnabled -LogFile $LogFile -Msg $line

        # Ignore everything before the marker
        if( $line.Trim() -eq $dexFile.marker ) {
            Write-Host " > Found pokemon data"
            $state = "POKEMON_DATA_FOUND"
        }

        # -----------------
        # Ending markers 
        if($dexFile.marker -eq "BULBASAUR") {
            $final_states = @("LV_MOVE_LIST_FOUND", "TM_MOVE_LIST_FOUND", "EGG_MOVE_LIST_FOUND", "TUTOR_MOVE_LIST_FOUND", "MEGA_INFO_FOUND", "LINKED_MOVE_LIST_FOUND", "ZYGARDE_CUBE_MOVE_LIST_FOUND")
            $is_footer = $line.contains("DataNinja") -and $line.contains("Homebrew")
            if( $is_footer -and ($final_states -contains $state) ) {
                $state = "POKEMON_DATA_FOUND"
                continue
            }
        }
        if($dexFile.marker -eq "DECIDUEYE Hisuian") {
            $final_states = @("LV_MOVE_LIST_FOUND", "TM_MOVE_LIST_FOUND", "EGG_MOVE_LIST_FOUND", "TUTOR_MOVE_LIST_FOUND", "MEGA_INFO_FOUND", "LINKED_MOVE_LIST_FOUND")
            $first_word = ($line.Trim() -split '\s+')[0]
            if( (-not ($first_word.Contains("§"))) -and (-not($line.Contains("Move List"))) -and ($first_word -ceq $first_word.ToUpper()) -and (-not ($first_word -match '^\d+$')) -and ($final_states -contains $state) ) {
                $state = "POKEMON_DATA_FOUND" 
            }
        }
        if($dexFile.marker -eq "Sprigatito") {
            $final_states = @("LV_MOVE_LIST_FOUND", "TM_MOVE_LIST_FOUND", "EGG_MOVE_LIST_FOUND", "TUTOR_MOVE_LIST_FOUND", "MEGA_INFO_FOUND", "LINKED_MOVE_LIST_FOUND")
            if( ($final_states -contains $state) -and ($line.Trim().Contains("______")) ) {
                $state = "POKEMON_DATA_FOUND" 
            }
        }

        # -----------------
        # Ignore empty lines and footer lines
        if( ( ($dexFile.marker -eq "BULBASAUR") -and $line.Contains("Unofficial PTU 1.05.5 PokéDex")) -or ($dexFile.marker -eq "Sprigatito" -and ($line.Contains("________"))) -or ($line.trim() -replace '\d', '') -eq "" ) {
            continue
        }
    
        # -----------------
        # Generate pokemon data entry
        if ($state -eq "POKEMON_DATA_FOUND") {        
            $pokemonData = Get-PokemonObject $line
            # Hoopa is a special case, with linked moves on its forms
            if( ($dexFile.marker -eq "BULBASAUR") -and $pokemonData.name.contains("Unbound") ){
                $pokemonData.move.linked = @("Hyperspace Fury", "Dark Pulse", "Knock Off")
            } 
            if( ($dexFile.marker -eq "BULBASAUR") -and $pokemonData.name.contains("Confined") ) {
                $pokemonData.move.linked = @("Hyperspace Hole", "Shadow Ball", "Phantom Force")
            } 
            if( ($dexFile.marker -eq "BULBASAUR") -and $pokemonData.name.contains("ZYGARDE") ){
                $pokemonData.move.core = @( 
                    @{name = "Core Enforcer"; sgn = $true}
                    @{name = "Dragon Dance"}
                    @{name = "Extreme Speed"}
                    @{name = "Thousand Arrows"; sgn = $true}
                    @{name = "Thousand Waves"; sgn = $true}
                )
            }
            $dex += $pokemonData
            $aux_pkmn = $pokemonData
            Write-Log -Enabled $LogEnabled -LogFile $LogFile -Msg ("Pokemon - " + $aux_pkmn.name)
            $state = "SEARCHING_EVO_LIST"
            continue
        }
    
        # -----------------
        # Iterate until we find the evolution list
        if ($state -eq "SEARCHING_EVO_LIST" -and $line.Trim().StartsWith("Evolution")) {
            Write-Log -Enabled $LogEnabled -LogFile $LogFile -Msg "  Evo line found"
            $state = "EVO_LIST_FOUND"
            continue
        }
    
        # -----------------
        # Populate the pokemon data with its evolution line   
        if ($state -eq "EVO_LIST_FOUND") {
            if ($line.Trim().StartsWith("Size Information") -or ($line.Trim().StartsWith("Other Information") -and $dexFile.marker -eq "Sprigatito")) {
                Write-Log -Enabled $LogEnabled -LogFile $LogFile -Msg "  Evo line finished"
                $state = "SEARCHING_MOVE_LIST"
                continue
            } elseif (-not $line.Trim() -eq "") {
                Write-Log -Enabled $LogEnabled -LogFile $LogFile -Msg ("    Evo: " + $line.Trim())
                $aux_pkmn.evo += $line.Trim()
            }
        }
    
        # -----------------
        # Iterate until we find the level up move list
        if($state -eq "SEARCHING_MOVE_LIST" -and $line.Trim().StartsWith("Level Up Move List") -or ($dexFile.marker -eq "Sprigatito" -and $line.Trim().StartsWith("Move List"))) {
            Write-Log -Enabled $LogEnabled -LogFile $LogFile -Msg "  Move List found"
            $state = "LV_MOVE_LIST_FOUND"
            continue
        }
    
        # -----------------
        # Populate the level up move list.
        if($state -eq "LV_MOVE_LIST_FOUND") {        
            # Multiple cases, some pokemon dont have TM, Tutor or Egg moves
            if ($line.Contains("TM Move List") -or ($line.Contains("TM/HM Move List") -or ($line.Contains("TM/Tutor Moves") ) ) ) {
                Write-Log -Enabled $LogEnabled -LogFile $LogFile -Msg "Found TM Move List"
                $state = "TM_MOVE_LIST_FOUND"
                continue
            } elseif ($line.Contains("Tutor Move List")) {
                Write-Log -Enabled $LogEnabled -LogFile $LogFile -Msg "Found Tutor Move List"
                $state = "TUTOR_MOVE_LIST_FOUND"
                continue
            } elseif ($line.Contains("Egg Move List")) {
                Write-Log -Enabled $LogEnabled -LogFile $LogFile -Msg "Found Egg Move List"
                $state = "EGG_MOVE_LIST_FOUND"
                continue
            } else {
                Write-Log -Enabled $LogEnabled -LogFile $LogFile -Msg ("    Move: " + $line.Trim())            
                # Move parsing is a bit complex, as there are multiple cases:
                # - Moves with a level
                # - Moves learned on Evo
                # - Moves with the § symbol, which means they are preferred moves
    
                # Obtain the level of the move
                $word_list_line = $line.Trim() -split ' '
                $lv_idx = ($line.contains("§") ? 1 : 0)
                $move_lv = $word_list_line[ $lv_idx ]
               
                # Obtain the name of the move
                if ($dexFile.marker -eq "Sprigatito" -and ($line -match '\d+ - (.+?) -')) {
                    # This is a special case for Gen 9, where the move list has a different format
                    $move_name = $matches[1].Trim()
                } elseif ($line -match '§ \d+ (.+?) -') {
                    # This is a case where the move has a level and is preferred by the pokemon
                    $move_name = $matches[1].Trim()
                } elseif ($line -match '§ Evo+ (.+?) -') {
                    # This is a case where the move is learned on evolution and is preferred by the pokemon
                    $move_name = $matches[1].Trim()
                } elseif ($line -match '\d+ (.+?) -') {
                    # This is a case where the move has a level and is not preferred by the pokemon
                    $move_name = $matches[1].Trim()
                } elseif ($dexFile.marker -eq "Sprigatito" -and ($line -match 'Evo+ - (.+?) -')) { 
                    # This is a special case for Gen 9, where the move list has a different format
                    $move_name = $matches[1].Trim()
                } elseif ($line -match 'Evo+ (.+?) -') { 
                    # This is a case where the move is learned on evolution and is not preferred by the pokemon
                    $move_name = $matches[1].Trim()
                }
                
                $move = @{
                    lv = $move_lv                         # This should always get the "word" that is the level
                    name = $move_name.Replace("’","'")    # This should always get the name of the move 
                }
                
                if($line.Contains("§")) {
                    $move.sgn = $line.Contains("§")
                }
                    
                $aux_pkmn.move.lv += $move
            }
        }
    
        # -----------------
        # If TM move list is found, we add to nonnatural moves
        if($state -eq "TM_MOVE_LIST_FOUND") {
            if ($line.Contains("Egg Move List")) {
                Write-Log -Enabled $LogEnabled -LogFile $LogFile -Msg "Found Egg Move List"
                $state = "EGG_MOVE_LIST_FOUND"
                $aux_pkmn.move.other += ","
                continue
            } elseif ($line.Contains("Tutor Move List")) {
                Write-Log -Enabled $LogEnabled -LogFile $LogFile -Msg "Found Tutor Move List"
                $state = "TUTOR_MOVE_LIST_FOUND"
                $aux_pkmn.move.other += ","
                continue
            } else {
                $aux_pkmn.move.other += ($line.Trim() -replace '\d', '') 
            }
        }  
    
        # -----------------
        # If egg move list is found, we add to nonnatural moves
        if($state -eq "EGG_MOVE_LIST_FOUND") {
            if ($line.Contains("Tutor Move List")) {
                Write-Log -Enabled $LogEnabled -LogFile $LogFile -Msg "Found Tutor Move List"
                $state = "TUTOR_MOVE_LIST_FOUND"            
                $aux_pkmn.move.other += ","
                continue
            } else {
                $aux_pkmn.move.other += ($line.Trim() -replace '\d', '')
            }
        }
    
        # -----------------
        # If tutor move list is found, we add to nonnatural moves
        if($state -eq "TUTOR_MOVE_LIST_FOUND") {
            # Cases with non required info, marked just so that they are not indexed by the nonnatural move list
            if($line.contains("Mega Evolution") -or $line.contains("Primal Reversion") -or $line.contains("Ultra Burst")) {
                $state = "MEGA_INFO_FOUND"            
                $aux_pkmn.move.other += ","
                continue
            }
            if($line.Contains("Linked Moves")) {
                $state = "LINKED_MOVE_LIST_FOUND"
                $aux_pkmn.move.other += ","
                continue
            }
            if($line.Contains("Zygarde Cube Move List")) {
                $state = "ZYGARDE_CUBE_MOVE_LIST_FOUND"
                $aux_pkmn.move.other += ","
                continue
            }
            $aux_pkmn.move.other += ($line.Trim() -replace '\d', '')
        }   
    }

}

# -------------------
# Process non-natural moves, to make a formatted list
$dex = Convert-OtherMoves -dex $dex

$dex = Convert-EvoLines -dex $dex

# Generate the new dex_info.json file
Write-DexFiles -dex $dex -fileName $conf.filename -fileNameCompressed $conf.compressed_filename
