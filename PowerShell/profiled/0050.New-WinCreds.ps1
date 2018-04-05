Function New-WinCreds 
{
	[CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ValueFromPipeline=$false)][string]$userName = "$env:USERNAME@$env:USERDOMAIN",
        [Parameter(Mandatory=$false, ValueFromPipeline=$false)][string]$path = $CredentialsPath
    )     
    
        $Credential = Get-Credential;
           $export = "" | Select-Object Username, Password
       
           $export.Username = $Credential.Username
           $export.Password = $Credential.Password | ConvertFrom-SecureString

		[string]$credFilename = (Get-NormalizedUsername -UserName $export.Username -ErrorAction Stop) + '.xml'
		Write-Debug "credFilename=$credFilename"

        if(Test-Path $path)
        {
            Write-Debug "'path='$path 'exists'"
            if((Get-Item $path) -is [System.IO.DirectoryInfo])
            {
                Write-Debug "$path 'is a directory'"
                $path = $path.TrimEnd('\') + '\' + $credFilename 
                Write-Debug "'new path: '$path"
            }            
        }
        else
        {
            Write-Host "Specified path doesn't exist. Trying to create..."
            $pathArr = $path.Split('\')
            if($pathArr[$pathArr.Length - 1] -like '*.xml')
            {
                [string]$pathLocation = ''
                for([int]$i = 0; $i -lt $pathArr.Length - 1; $i++)
                {
                    $pathLocation = $pathLocation + $pathArr[$i] + '\'
                }
                try
                {
                    mkdir $pathLocation
                }
                catch
                {
                    Write-Error 'Something went wrong' -ErrorAction:Continue
                }
            }
            else
            {
                try
                {
                    New-Item -Path $path -ItemType Directory -Force
                    $path = $path.Trim('\') + '\' + $credNameUnsafe + '.xml'
                }
                catch
                {
                    Write-Error 'Something went wrong'
                }
            }
        }          
        
        if(($export.Username -ne $null) -and ($export.Username -ne ''))
        {
           $export | Export-Clixml $path
           Write-Host "Credential Save Complete"
        }
        else 
        {
            Write-Error 'Nothing to save since username is null' -ErrorAction Stop    
        }       
} 