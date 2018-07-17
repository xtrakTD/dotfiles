function nano {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$false)][string]$File
    )

    bash -c "nano $File"
}

function vim {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$false)][string]$File
    )
    
    bash -c "vim $File"
}