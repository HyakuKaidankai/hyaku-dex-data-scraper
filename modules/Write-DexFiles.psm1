function Write-DexFiles {
    <#
    .SYNOPSIS
        Writes the Pokedex files to disk.
    #>
    param(
        $dex,
        [string]$fileName = ".\dex_info.json",
        [string]$fileNameCompressed = ".\dex_info_compressed.json"
    )

    Write-Host "- Generating dex files"
    Remove-Item -Path $fileName -ErrorAction SilentlyContinue
    Remove-Item -Path $fileNameCompressed -ErrorAction SilentlyContinue
    $json_debug = $dex | ConvertTo-Json -Depth 100
    $json_compressed = $dex | ConvertTo-Json -Depth 100 -Compress
    $json_debug | Out-File -FilePath $fileName -Encoding utf8
    $json_compressed | Out-File -FilePath $fileNameCompressed -Encoding utf8
}

Export-ModuleMember -Function Write-DexFiles