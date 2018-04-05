function Check-HostUserMap {

	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$false)][string]$RemoteHostName='',
		[Parameter(Mandatory=$false, ValueFromPipeline=$false)][string]$BypassUsername=$null
	)

	if($BypassUsername -ne $null -or $BypassUsername -ne '') {
		return $BypassUsername
	}

	[string]$MainUserName=''

	if(
		($RemoteHostName -match '^\d{1,2}?\-(asb|ad)?(web)(\d{2})?(.+)?') -or
		($RemoteHostName -match '^\d{1,3}?\-(asb|ad)?(services)(.+)?') -or
		($RemoteHostName -match '^\d{1,2}?\-(asb|ad)?(sql)(.+)?')) {
			[bool]$TestStand = $true
		}
	
		elseif($RemoteHostName -match '^(griffin|rook)(.+)?') {
			[bool]$TestRail = $true
		}

		elseif($RemoteHostName -match '^\d{1,3}\-(asb|ad|cp)?(docker)(.+)?') {
			[bool]$BashTerminalSession = $true
		}

		elseif($RemoteHostName -match '^(.+)?(scom|scvmm|stage|heart|chimera') {
			[bool]$StageInfrastructuee = $true
		}
	
		else {
			[bool]$ITOnlineConnection=$true
		}
	
	if((Get-ChildItem env:BASEUSERNAME -ErrorAction SilentlyContinue) -eq $null) {
		$MainUserName = Read-Host -Prompt 'Enter your IT-ONLINE username : '
		[Environment]::SetEnvironmentVariable('BASEUSERNAME', $MainUserName, 'User')
	}
	else {
		$MainUserName = $env:BASEUSERNAME
	}

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

	return $CredsUserName
}

