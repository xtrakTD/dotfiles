Function Get-TimeDiff
{
	[CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)][DateTime]$StartTime
    )

    return New-TimeSpan -Start $StartTime -End (Get-Date) 
}