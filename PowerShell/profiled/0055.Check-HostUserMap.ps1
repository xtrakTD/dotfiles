function Check-HostUserMap {

	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$false)][string]$RemoteHostName='',
		[Parameter(Mandatory=$false, ValueFromPipeline=$false)][string]$BypassUsername=$null
	)

	if($BypassUsername -ne $null -and $BypassUsername -ne '') {
		Write-Host "Returning bypass username [$BypassUsername]"
		return $BypassUsername
	}

	[string]$MainUserName=''

	if(
		($RemoteHostName -match '^\d{1,2}?\-(asb|ad)?(web)(\d{2})?(.+)?') -or
		($RemoteHostName -match '^\d{1,3}?\-(asb|ad)?(services)(.+)?') -or
		($RemoteHostName -match '^\d{1,2}?\-(asb|ad)?(sql)(.+)?')) {
			[bool]$TestStand = $true
			Write-Host "RemoteHost is a TestStand"
		}
	
		elseif($RemoteHostName -match '^(griffin|rook)(.+)?') {
			[bool]$TestRail = $true
			Write-Host "RemoteHost is a TestRail"			
		}

		elseif(($RemoteHostName -match '^\d{1,3}\-(asb|ad|cp)?(docker)(.+)?') -or
			   ($RemoteHostName -match '^((\w+)?\@)?(\d{1,3}\.){3}\d{1,3}$')) {
				[bool]$BashTerminalSession = $true
				Write-Host "RemoteHost is a Linux"			
		}

		elseif($RemoteHostName -match '^(.+)?(scom|scvmm|stage|heart|chimera)') {
			[bool]$StageInfrastructuee = $true
			Write-Host "RemoteHost is a Infrastructure"			
		}
	
		else {
			[bool]$ITOnlineConnection=$true
			Write-Host "RemoteHost is in ITO domain"			
		}
	
	Write-Host "USERNAME is [$env:USERNAME]"
		
	if( -not ($env:USERNAME -match '^(\w{1,2})\.(.+)$')) {
		$MainUserName = Read-Host -Prompt 'Enter your IT-ONLINE username : '		
	}
	else {
		$MainUserName = $env:USERNAME
	}

	Write-Host "MainUserName is [$MainUserName]"

	[string]$CredsUserName = ''

	if($TestStand) {
		$CredsUserName = $MainUserName+'@stage.stage'
	}
	elseif($BashTerminalSession) {
		$CredsUserName = "ansible@" + $RemoteHostName
	}
	elseif($StageInfrastructuee) {
		$CredsUserName = 'scomuser@stage.stage'
	}
	elseif($TestRail) {
		$CredsUserName = $MainUserName+'@stage.stage'
	}
	elseif($ITOnlineConnection) {
		$CredsUserName = $MainUserName+'@it-online.ru'
	}
	else {
		Write-Host "Couldn't map host [ ""+$RemoteHostName+' ] to user" -BackgroundColor Yellow -ForegroundColor DarkRed
		$CredsUserName = $env:USERNAME + "@" + $env:USERDOMAIN
	}

	Write-Host "CredsUserName is [$CredsUserName]"

	return $CredsUserName
}

