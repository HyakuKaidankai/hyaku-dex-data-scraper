function Write-DexFiles {
    <#
    .SYNOPSIS
        Writes the Pokedex files to disk.
    #>
    param(
        $dex
    )

    Write-Host "- Generating dex files"
    Remove-Item -Path ".\dex_info.json" -ErrorAction SilentlyContinue
    Remove-Item -Path ".\dex_info_compressed.json" -ErrorAction SilentlyContinue
    $json_debug = $dex | ConvertTo-Json -Depth 100
    $json_compressed = $dex | ConvertTo-Json -Depth 100 -Compress
    $json_debug | Out-File -FilePath ".\dex_info.json" -Encoding utf8
    $json_compressed | Out-File -FilePath ".\dex_info_compressed.json" -Encoding utf8
}

Export-ModuleMember -Function Write-DexFiles