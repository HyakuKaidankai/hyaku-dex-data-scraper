function Convert-OtherMoves {
    <#
    .SYNOPSIS
        Converts the non-lvl moves of a Pokemon, from the original string list to a list of parsed objects.
    #>
    param(
        $dex
    )

    Write-Host "Move conversion started"
    foreach ($pkmn in $dex) {
        $aux_moves = @()

        # Transform the string into an array, and replace some of the stuff that could be cut off, product of the txt file format
        $joinedList = $pkmn.move.other -join " "
        $resultArray = $joinedList -split ',\s*' | Where-Object { ($_ -match '\S') } | ForEach-Object {
            $res = $_.Trim() -replace '\s+', ' '
            $res = $res -replace 'Mud- Slap', 'Mud-Slap'  -replace 'Will-O- Wisp', 'Will-O-Wisp' -replace 'U- Turn', 'U-Turn'
            $res = $res -replace 'Double- Edge', 'Double-Edge' -replace 'Will- O-Wisp', 'Will-O-Wisp' -replace 'X- Scissor', 'X-Scissor'
            return $res
        } | Select-Object -Unique
        $pkmn.move.other = $resultArray
    
        foreach($move in $pkmn.move.other) {
            
            # If this triggers, it means the move needs to be added to the replace list that is above
            if($move.Contains("- ")) {
                Write-Host $move
                exit
            }
    
            # Remove unwanted symbols from the name, as they should be replace for separate attributes in the object
            $move_obj = @{
                name = $move.Replace("(N)", "").Trim().Replace("§", "").Trim().Replace("’","'")
            }
            if($move.Contains("(N)")) {
                $move_obj.natural = $move.Contains("(N)")
            }
            if($move.Contains("§")) {
                $move_obj.sgn = $move.Contains("§")
            }
            $aux_moves += $move_obj
        }
    
        $pkmn.move.other = $aux_moves
    }

    Write-Host "Move conversion finished"
    return $dex
}

Export-ModuleMember -Function Convert-OtherMoves