function Get-NormalizedUsername {
	
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)][string]$UserName="$env:USERNAME@$env:USERDOMAIN",
		[Parameter(Mandatory=$false, ValueFromPipeline=$false)][char]$NormalizationChar='_'
	)

	if($UserName -match '^(.+)?\\(.+)$') {
		[string[]]$temp = $UserName.Split('\')
		$UserName = $temp[1]+'@'+$temp[0]
	}

	[string]$normalized = $UserName.ToLower() -replace '[^a-zA-Z0-9]+', $NormalizationChar
	
	return $normalized
}