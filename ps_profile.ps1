#INPUT PARAMS

param(
    [Parameter(Mandatory=$false)][switch]$StageConsole=$true,
    [Parameter(Mandatory=$false)][switch]$DetailedOutput=$true
)

#ASSEMBLIES

[Void][Reflection.Assembly]::LoadWithPartialName("System.Collections.Generic")
[Void][Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")

#COMMON VARS

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

if($DetailedOutput)
{
    $DebugPreference='Continue' 
    $VerbosePreference='Continue'
    $InformationPreference='Continue'
}

$ErrorView='NormalView'

#MODULES

if($StageConsole)
{
    if($DetailedOutput)
    {
        Import-Module \\stage.stage\heart\Infrastructure.stage$\Scripts\Deploy.stage\StageDeploy.psm1 -Verbose -ErrorAction Continue
    }
    else
    {
        Import-Module \\stage.stage\heart\Infrastructure.stage$\Scripts\Deploy.stage\StageDeploy.psm1 -ErrorAction SilentlyContinue | Out-Null
    }
}

Import-Module PowerShellGet -ErrorAction Stop

if((Get-Command Get-ChildItemColor -ErrorAction SilentlyContinue) -eq $null)
{
    Install-Module Get-ChildItemColor -Scope CurrentUser -Force
}

#FUNCTIONS

Function Test-Administrator 
{
    [CmdletBinding()]
    param()

    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    [bool]$IsAdmin = (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

    Set-Variable -Name IsAdminSession -Value $IsAdmin -Scope Global

    return $IsAdmin
}

Function Install-ThemeEngine
{
    [CmdletBinding()]
    param()
    
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    
    if((Get-Command scoop -ErrorAction SilentlyContinue) -eq $null)
    {
        Invoke-Expression(New-Object Net.Webclient).DownloadString('https://get.scoop.sh')
    }

    scoop install git pshazz

    if((Get-Command pshazz -ErrorAction SilentlyContinue) -eq $null)
    {
        Write-Error 'Something went wrong during PSHazz installation. Try again later' -ErrorAction Continue
    }          
}

Function Get-FileLock
{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$false)][string]$FileOrFolderPath
    )

    if ((Test-Path -Path $FileOrFolderPath) -eq $false) 
    { 
        Write-Warning "File or directory does not exist."     
    } 
    else 
    { 
        $LockingProcess = CMD /C "openfiles /query /fo table | find /I ""$FileOrFolderPath""" 
        Write-Host $LockingrPocess 
    }
}

Function Get-WinCreds
{
    param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$false)][SecureString]$credName=(ConvertTo-SecureString 'creds' -AsPlainText -Force),
        [Parameter(Mandatory=$false, ValueFromPipeline=$false)][string]$path=($env:USERPROFILE+'\'+[System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credName))+'.xml')
    )          
        Write-Debug "looking for creds in $path"
        $import = Import-CLixml $path
       
           $Username = $import.Username 
           $SecurePassword = $import.Password | ConvertTo-SecureString
       
           $Credential = New-Object System.Management.Automation.PSCredential $Username, $SecurePassword
           Write-Debug "username: $Username"
           return $Credential
}

Function New-WinCreds 
{
    param (
        [Parameter(Mandatory=$false, ValueFromPipeline=$false)][SecureString]$credName =(ConvertTo-SecureString 'creds' -AsPlainText -Force),
        [Parameter(Mandatory=$false, ValueFromPipeline=$false)][string]$path = $env:USERPROFILE
    )     
        [string]$credNameUnsafe = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credName))
        
        Write-Debug "'credNameUnsafe='$credNameUnsafe"

        $Credential = Get-Credential;
           $export = "" | Select-Object Username, Password
       
           $export.Username = $Credential.Username
           $export.Password = $Credential.Password | ConvertFrom-SecureString

        if(Test-Path $path)
        {
            Write-Debug "'path='$path 'exists'"
            if((Get-Item $path) -is [System.IO.DirectoryInfo])
            {
                Write-Debug "$path 'is a directory'"
                $path = $path.TrimEnd('\') + '\' + $credNameUnsafe + '.xml'
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
                    mkdir $path
                    $path = $path.Trim('\') + '\' + $credName + '.xml'
                }
                catch
                {
                    Write-Error 'Something went wrong'
                }
            }
        }          
               
           $export | Export-Clixml $path
           Write-Host "Credential Save Complete"
}        

Function New-RemotePSSession
{
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$RemoteServer,
        [Parameter(Mandatory=$false, ValueFromPipeline=$false)][PSCredential]$Credentials=$null,
        [Parameter(Mandatory=$false, ValueFromPipeline=$false)][switch]$ConfigureWinRM=$false,
        [Parameter(Mandatory=$false, ValueFromPipeline=$false)][switch]$UseSSL=$false
    )

    if($RemoteServer -match "^(\d(\d{1,2})?\-)(.+)?((web)|(services)|(sql)|(docker))(\d{2})?(.+)?")
    {
        if(-not ($RemoteServer -match "^(.+)?(\.stage){2}$"))
        {
            $RemoteServer += '.stage.stage'
        }
    }
    
    if($ConfigureWinRM)
    {
        if(-not (Test-Administrator | Out-Null))
        {
            Write-Warning 'Current user is not an Administrator. Elevated priveleges are required to configure Remoting Services!'
        }        

        [System.Collections.Generic.Dictionary[string,string]]$WinRMProperties = New-Object -TypeName 'System.Collections.Generic.Dictionary[string,string]'
        
        $WinRMService = Get-WmiObject -Class win32_service -Filter "Name='WinRM'"
        
        $WinRMProperties.Add('State', [string]($WinRMService.State))
        $WinRMProperties.Add('StartMode', [string]($WinRMService.StartMode))
        
        Write-Host 'WinRM service State: ['$($WinRMProperties['State'])'], StartMode: ['$($WinRMProperties['StartMode'])']' -ForegroundColor White -BackgroundColor DarkRed
        
        if($WinRMProperties['State'] -ne 'Running')
        {
            Write-Host 'Trying to start WinRM service and finish configuration...' -ForegroundColor Yellow

            if($WinRMProperties['StartMode'] -eq 'Disabled')
            {
                try
                {
                    $WinRMService.ChangeStartMode('Manual')
                }
                catch
                {
                    Write-Warning 'Unable to change startup mode for WinRM service'                    
                }                
            }
            
            if($WinRMService.StartService().ReturnValue -ne 0)
            {
                Write-Warning 'Unable to start WinRM service on localhost'                    
            }

            [DateTime]$startTime = Get-Date
            [TimeSpan]$TimeDiff = New-Object -TypeName 'TimeSpan' 

            while(-not $WinRMService.Started -and $TimeDiff.TotalSeconds -lt 3.00)
            {
                # Refresh WinRM service status
                $WinRMService = Get-WmiObject -Class win32_service -Filter "Name='WinRM'"
                $WinRMProperties['State'] = $WinRMService.State

                Write-Debug "Checking WinRM service state.... :[$($WinRMProperties['State'])]"
                Start-Sleep -Milliseconds 500
                
                $TimeDiff = Get-TimeDiff -StartTime $startTime
            }

            if($WinRMProperties['State'] -ne 'Running')
            {
                Write-Error 'Unable to start WinRM service. Refer to Windows Event Logs for details' -ErrorAction:Continue
            }            
        }

        $WinRMService = Get-WmiObject -Class win32_service -Filter "Name='WinRM'"
        
        $WinRMProperties['State'] = [string]($WinRMService.State)
        $WinRMProperties['StartMode'] = [string]($WinRMService.StartMode)
        
        Write-Host 'WinRM service State: ['$($WinRMProperties['State'])'], StartMode: ['$($WinRMProperties['StartMode'])']' -ForegroundColor White -BackgroundColor DarkRed\

        if($WinRMProperties['State'] -eq 'Running')
        {
            $tHosts = ([string](Get-Item WSMan:\localhost\Client\TrustedHosts).Value).Split(',')
            
            if(($tHosts|?{$_ -eq '*'}) -eq $null)
            {
                Set-Item WSMan:\localhost\Client\TrustedHosts -Value '*' -Force -ErrorAction SilentlyContinue
            }
        }
    }   

        if($Credentials -eq $null)
        {
            Get-WinCreds | Out $Credentials

            if($Credentials -eq $null)
            {
                New-WinCreds | Out $Credentials
            }
        }

    if($UseSSL)
    {
        Enter-PSSession(New-PSSession -ComputerName $RemoteServer -UseSSL -Credential $Credentials)
    }
    else
    {
        Enter-PSSession(New-PSSession -ComputerName $RemoteServer -Credential $Credentials)
    }

   # if(($RemoteServer -match '^\d{1,2}?\-(asb|ad)?(web)(\d{2})?(.+)?') `
   #     -and $Global:IsAdminSession)
   # {
   #     Write-Host 'Loading Web.Administration Tools' -ForegroundColor White -BackgroundColor DarkRed
   #
   #     [Microsoft.Web.Administration.ServerManager]$ServerManager = New-Object Microsoft.Web.Administration.ServerManager
   #     $webnodeAppPools = $ServerManager.ApplicationPools
   #     $webnodeSites = $ServerManager.Sites
   # }
}

Function Get-TimeDiff
{
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)][DateTime]$StartTime
    )

    return New-TimeSpan -Start $StartTime -End (Get-Date) 
}

#MORE MODULES

if((Get-Command pshazz -ErrorAction SilentlyContinue) -eq $null)
{
    Install-ThemeEngine -ErrorAction Stop
}

if((Test-Administrator | Out-Null) -eq $true)
{
    Import-Module WebAdministration -ErrorAction Continue -Force
}

#ALIASES

if((Get-Alias -Name connect -ErrorAction SilentlyContinue) -eq $null)
{
    New-Alias -Name connect -Value New-RemotePSSession -Option AllScope
}

Set-Alias -Name ls -Value Get-ChildItemColorFormatWide -Option AllScope -Force
Set-Alias -Name dir -Value Get-ChildItemColor -Option AllScope -Force

if((Get-Alias -Name eps -ErrorAction SilentlyContinue) -eq $null)
{
    New-Alias -Name eps -Value Enter-PSSession
}

# INITIALIZATION 

Test-Administrator -ErrorAction Continue | Out-Null

if(-not (Test-Path $env:USERPROFILE\.psreadline))
{
    New-Item -Path $env:USERPROFILE -Name .psreadline -ItemType Directory
}

Set-PSReadlineOption -HistorySavePath $env:USERPROFILE\.psreadline\history.txt

[string[]]$themes=(pshazz list).Split([System.Environment]::NewLine)
if(($themes | ?{ $_.Trim() -eq 'dm' }) -eq $null)
{
    New-Item -Path $env:USERPROFILE\pshazz -Name dm.json -ItemType File -Value '
    
    {
	    "comment": "Dmitry Minin 2018",
	    "plugins": [ "git", "ssh", "z", "aliases" ],
	    "prompt": [
		    [ "White", "DarkRed", " $time " ],
		    [ "DarkRed", "Blue", "$rightarrow" ],
		    [ "White", "Blue", " $path " ],
		    [ "Blue", "", "$no_git" ],
		    [ "Blue", "Green", "$yes_git" ],
		    [ "DarkBlue", "Green", " $git_lbracket" ],
		    [ "DarkBlue", "Green", "$git_branch" ],
		    [ "DarkGreen", "Green", " $git_local_state" ],
		    [ "DarkGreen", "Green", " $git_remote_state" ],
		    [ "DarkBlue", "Green", "$git_rbracket " ],
		    [ "Green", "", "$yes_git" ],
		    [ "", "", " `n$" ]
	    ],
	    "git": {
		    "prompt_lbracket": "[",
		    "prompt_rbracket": "]",
		    "prompt_unstaged": "*",
		    "prompt_staged": "+",
		    "prompt_stash": "$",
		    "prompt_untracked": "%",
		    "prompt_remote_push": ">",
		    "prompt_remote_pull": "<",
		                "prompt_remote_same": "="
	                    },w
	                    "hg": {
		                    "prompt_dirty": "*"
	                    }
                    }
                    '
}
pshazz init dm

# CLEANUP VARS
