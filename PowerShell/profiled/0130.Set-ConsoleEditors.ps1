function Get-UnixFilename {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$WinFileName
    )

    [string]$unixPath = $WinFileName.Replace('\', '/').Replace(':','')

    if(!($unixPath.ToCharArray()[0] -eq '.')) {
        $unixPath = '/' + $unixPath
    }

    return $unixPath
}
function nano {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$false)][string]$File
    )

    $unixFile = Get-UnixFilename $File

    bash -c "nano $unixFile"
}
function vim {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$false)][string]$File
    )

    $unixFile = Get-UnixFilename $File

    bash -c "vim $unixFile"
}