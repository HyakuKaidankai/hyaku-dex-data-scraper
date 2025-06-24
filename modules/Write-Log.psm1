function Write-Log
{
    Param (
        [Parameter(Mandatory = $true)]
        [string]$Msg,
        [Parameter(Mandatory = $true)]
        [boolean]$Enabled,
        [Parameter(Mandatory = $true)]
        [string]$LogFile,        
        [string]$stampFormat = "yyyy/MM/dd HH:mm:ss"
    )
    if (-not $logEnabled) {
        return
    }
    $Stamp = (Get-Date).toString($stampFormat)
    $LogMessage = "$Stamp $Msg"
    Add-content $LogFile -value $LogMessage -Encoding UTF8
}