Function New-RemotePSSession
{
	[CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$RemoteServer,
		[Parameter(Mandatory=$false, ValueFromPipeline=$false)][string]$userName='',
        [Parameter(Mandatory=$false, ValueFromPipeline=$false)][PSCredential]$Credentials,
        [Parameter(Mandatory=$false, ValueFromPipeline=$false)][switch]$ConfigureWinRM=$false,
        [Parameter(Mandatory=$false, ValueFromPipeline=$false)][switch]$UseSSL=$false,
		[Parameter(Mandatory=$false, ValueFromPipeline=$false)][switch]$UseDefaults=$false
    )

    if($RemoteServer -match "^(\d(\d{1,2})?\-)(.+)?((web)|(services)|(sql)|(docker))(\d{2})?(.+)?")
    {
        if(-not ($RemoteServer -match "^(.+)?(\.stage){2}$"))
        {
           $RemoteServer += '.stage.stage'
        }
    }

	if(!$Credentials)
    {
		if($UseDefaults) {
			$userName = Check-HostUserMap -RemoteHostName $RemoteServer -ErrorAction Continue
		}
		
		$Credentials = Get-WinCreds -userName $userName -ErrorAction SilentlyContinue
		
		if(!$Credentials) {
			$Credentials = New-WinCreds -userName $userName			
		}      
    }
    
    if($ConfigureWinRM)
    {
        if(-not (Test-Administrator | Out-Null))
        {
            Write-Warning 'Current user is not an Administrator. Elevated priveleges are required to configure Remoting Services!' -WarningAction:Continue
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

                Write-Debug "Checking WinRM service state.... :["$WinRMProperties['State']"]"
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
        
        Write-Host 'WinRM service State: ['$($WinRMProperties['State'])'], StartMode: ['$($WinRMProperties['StartMode'])']' -ForegroundColor White -BackgroundColor DarkRed

        if($WinRMProperties['State'] -eq 'Running')
        {
            $tHosts = ([string](Get-Item WSMan:\localhost\Client\TrustedHosts).Value).Split(',')
            
            if(($tHosts|?{$_ -eq '*'}) -eq $null)
            {
                Set-Item WSMan:\localhost\Client\TrustedHosts -Value '*' -Force -ErrorAction SilentlyContinue
            }
        }
    }          

    if($UseSSL)
    {
        $session = New-PSSession -ComputerName $RemoteServer -UseSSL -Credential $Credentials
    }
    else
    {
        $session = New-PSSession -ComputerName $RemoteServer -Credential $Credentials
    }

    if($RemoteServer -match '^\d{1,2}?\-(asb|ad)?(web)(\d{2})?(.+)?')
    {
        [scriptblock]$func = {

            Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
            
            [Void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")

            Function New-CustomAppPool { 
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)][Microsoft.Web.Administration.ApplicationPool]$AppPool
                )
                [Void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")
                $customPoolObj = New-Object psobject

                Add-Member -InputObject $customPoolObj -MemberType NoteProperty -Name ApplicationPool -Value $AppPool
                Add-Member -InputObject $customPoolObj -MemberType NoteProperty -Name CustomProperties -Value (New-Object psobject)
                Add-Member -InputObject $customPoolObj.CustomProperties -MemberType NoteProperty -Name IsRecycleOk -Value ([bool]$false)

                return $customPoolObj
            }

            Function New-CustomWebSite { 
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)][Microsoft.Web.Administration.Site]$WebSite
                )
                [Void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")
                $customSiteObj = New-Object psobject

                Add-Member -InputObject $customSiteObj -MemberType NoteProperty -Name Site -Value $WebSite
                Add-Member -InputObject $customSiteObj -MemberType NoteProperty -Name CustomProperties -Value (New-Object psobject)            

                return $customSiteObj
            }

			Function Recycle-IISAppPools {
				[CmdletBinding()]
				param(
					[Parameter(Mandatory=$false, ValueFromPipeline=$true)][string[]]$AppPools,
					[Parameter(Mandatory=$false, ValueFromPipeline=$false)][Microsoft.Web.Administration.ServerManager]$ServerManager=(New-Object -TypeName 'Microsoft.Web.Administration.ServerManager')
				)

				if(!$AppPools) {	
					$AppPools = (
						$ServerManager.ApplicationPools | 
							Where-Object { 
								($_.State -eq 'Started') -and
								(-not ($_.Name -like '.NET v*')) -and
								(-not ($_.Name -like 'DefaultAppPool')) -and
								(-not ($_.Name -like 'Classic .NET*'))
							}).Name
				}

				$AppPools | ForEach-Object -Process {
					[string]$currentPool = $_
					try {
						if($ServerManager.ApplicationPools[$_].Recycle() -eq 'Started') {
							Write-Host "Recycle AppPool [ " -NoNewline
							Write-Host $_ -ForegroundColor White -NoNewline
							Write-Host " ] - [ " -NoNewline
							Write-Host "OK" -ForegroundColor Green -NoNewline
							Write-Host " ]"
						}
					}
					catch {
						Write-Host "Recycle error for AppPool " -ForegroundColor Red -NoNewline
						Write-Host "[ $currentPool ]" -BackgroundColor DarkRed -ForegroundColor Yellow 
					}
				}
			}

            $sm = New-Object -TypeName 'Microsoft.Web.Administration.ServerManager'

        
            [hashtable]$pools = New-Object -TypeName System.Collections.Hashtable
            $sm.ApplicationPools | %{ $pools.Add($_.Name, (New-CustomAppPool -AppPool $_)) }

            [hashtable]$sites = New-Object -TypeName System.Collections.Hashtable
            $sm.Sites | %{ $sites.Add($_.Name, (New-CustomWebSite -WebSite $_)) }
			
            cd e:\
            clear

			Write-Host "Added site objects, IIS pool objects and functions" -BackgroundColor Yellow -ForegroundColor DarkRed
        }

        Invoke-Command -Session $session -ScriptBlock $func 
    }

    if($RemoteServer -match '^\d{1,3}?\-(asb|ad)?(services)(.+)?')
    {
        [scriptblock]$func = {
            Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force

            Function New-CustomService {
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)][psobject]$Service
                )
              
                $customServiceObject = New-Object psobject
                
                Add-Member -InputObject $customServiceObject -MemberType NoteProperty -Name Service -Value $Service
                Add-Member -InputObject $customServiceObject -MemberType NoteProperty -Name CustomProperties -Value (New-Object psobject)

                return $customServiceObject
            }
            
            [string]$prefix = ''
            [string]$testString = $RemoteServer.Split('-')[1].Substring(0, 2)

            if($testString -eq 'ad')
            {
                $prefix = 'ad'
            }
            else
            {
                $prefix = 'ob'
            }

            [hashtable]$services = New-Object -TypeName System.Collections.Hashtable
            $tempsvcs = Get-WmiObject -Class Win32_Service -Filter "Name like ""$prefix.%"""

            $tempsvcs | %{ $services.Add($_.Name, (New-CustomService -Service $_)) }

            cd e:\
            clear

			Write-Host "Added service objects" -BackgroundColor Yellow -ForegroundColor DarkRed
        }

        Invoke-Command -Session $session -ScriptBlock $func
    }

    Enter-PSSession $session
}