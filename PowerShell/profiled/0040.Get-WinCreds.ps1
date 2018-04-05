Function Get-WinCreds
{
	[CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$false)][string]$userName="$env:USERNAME@$env:USERDOMIAN",
        [Parameter(Mandatory=$false, ValueFromPipeline=$false)][string]$path=$CredentialsPath
    )
    
        if((Get-Item $path) -is [System.IO.DirectoryInfo])
        {
			Write-Debug "[$path] is a directory"
            $path = $path.TrimEnd('\')+'\'+(Get-NormalizedUsername -UserName $userName -ErrorAction Stop)+'.xml'
			Write-Debug "new path: [$path]"
        }

        Write-Debug "looking for creds in $path"
        $import = Import-CLixml $path
       
           $Username = $import.Username 
           $SecurePassword = $import.Password | ConvertTo-SecureString
       
           $Credential = New-Object System.Management.Automation.PSCredential $Username, $SecurePassword
           Write-Debug "username: $Username"
           return $Credential
}