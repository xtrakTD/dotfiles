Write-Host 'Installing dotfiles PowerShell profile....' -BackgroundColor Yellow -ForegroundColor DarkRed
Write-Host 'Checking installation package...'

[bool]$packageOK = $true
[string]$installationRoot = (Get-Location).Path

if(((Test-Path .\profile\Microsoft.PowerShell_profile.ps1 -PathType Leaf -ErrorAction Stop) -eq $true) -and $packageOK) {
	if(((Test-Path .\Modules\pshazz\plugins\xtr.ps1 -PathType Leaf -ErrorAction Stop) -eq $true) -and $packageOK) {
		if(((Test-Path .\Modules\pshazz\themes\xtr.json -PathType Leaf -ErrorAction Stop) -eq $true) -and $packageOK) {
			Write-Host 'Package OK' -BackgroundColor Green -ForegroundColor DarkBlue
		}
		else {
			$packageOK = $false
		}
	}
	else {
		$packageOK = $false
	}
}
else {
	$packageOK = $false
}

if($packageOK) {
	Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
	if((Get-Command pshazz -ErrorAction SilentlyContinue) -eq $null) {
		Write-Host 'PSHAZZ not installed... ' -ForegroundColor Red
		
		if((Get-Command scoop -ErrorAction SilentlyContinue) -eq $null) {
			Write-Host 'Scoop not installed either. Installing required prerequisites' -BackgroundColor Red -ForegroundColor Yellow

			Invoke-Expression(New-Object Net.Webclient).DownloadString('https://get.scoop.sh')

			if((Get-Command scoop -ErrorAction SilentlyContinue) -ne $null) {
				Write-Host 'SCOOP installation successful.' -ForegroundColor Green
			}
		}

		Write-Host 'Installing PSHAZZ and reuiqred modules'
		scoop install 7zip git pshazz

		if((Get-Command pshazz -ErrorAction SilentlyContinue) -eq $null)
		{
			Write-Error 'Something went wrong during PSHazz installation. Try again later' -ErrorAction Continue
		}         
	}

	Write-Host 'Checking PSHAZZ installation again.'
	if((Get-Command pshazz -ErrorAction SilentlyContinue) -ne $null) {
		Write-Host 'Installation OK' -ForegroundColor Green -NoNewline
		Write-Host ' Updating pshazz to custom build by XTR.'

		$fromDir = "$installationRoot\Modules\pshazz"
		$toDir = "$env:USERPROFILE\scoop\apps\pshazz\current"
		
		Copy-Item -Path $fromDir\* -Destination $toDir -Recurse -Force -Verbose
	}

	if((Test-Path -Path $toDir\plugins\xtr.ps1 -PathType Leaf) -eq $true) {
		Write-Host 'Update OK' -ForegroundColor Green
	}

	Write-Host 'Installing PS profile'
	$profileDir = $PROFILE.Replace($PROFILE.Split('\')[$PROFILE.Split('\').Count - 1], '')
	
	if((Test-Path $PROFILE -PathType Leaf -ErrorAction SilentlyContinue) -ne $null) {
		Copy-Item -Path $PROFILE -Destination $PROFILE"_backup"
	}

	if((Test-Path $profileDir -PathType Container -ErrorAction SilentlyContinue) -eq $null) {
		mkdir $profileDir -ErrorAction Stop		
	}

	Copy-Item -Path $installationRoot\profile\Microsoft.PowerShell_profile.ps1 -Destination $PROFILE -Force -ErrorAction Stop

	Write-Host "Installing script sources..."

	if((Test-Path "$profileDir\profiled" -PathType Container -ErrorAction SilentlyContinue) -eq $null) {
		mkdir "$profileDir\profiled" -ErrorAction Stop
	}

	Copy-Item -Path $installationRoot\profiled -Include *.ps1 -Destination "$profileDir\profiled" -Force -Recurse -Verbose -ErrorAction Stop

	if((Test-Path -Path "$profileDir\profiled\0100.Set-Aliases.ps1" -Pa thType Leaf -ErrorAction SilentlyContinue) -ne $null) {
		Write-Host "Script sources installed OK" -ForegroundColor Green
	}

	[string]$start = (Read-Host 'Open new console to apply changes? (Y/N) :')
	if($start.ToLowerInvariant() -eq 'y' -or $start.ToLowerInvariant() -eq 'yes') {
		start powershell
	}
}