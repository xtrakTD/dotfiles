Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force

Write-Host 'Installing dotfiles PowerShell profile....' -BackgroundColor Yellow -ForegroundColor DarkRed
Write-Host 'Checking installation package...'

[string]$profileDir = $PROFILE.Replace($PROFILE.Split('\')[$PROFILE.Split('\').Count - 1], '')
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

	Write-Host 'Checking Write-Ascii module.'
	if((Get-Command Write-Ascii -ErrorAction SilentlyContinue) -eq $null)
	{
		Write-Host 'Module not found. Installing...'
		
		$fromDir = "$installationRoot\Modules\Write-Ascii"
		$toDir = "$profileDir\Modules\Write-Ascii"

		if ((Test-Path -Path $toDir -PathType Container) -eq $false) {
			mkdir $toDir -ErrorAction Stop
		}
		
		Copy-Item -Path $fromDir\* -Destination $toDir -Recurse -Force
	}

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
		
		Copy-Item -Path $fromDir\* -Destination $toDir -Recurse -Force
	}

	if((Test-Path -Path $toDir\plugins\xtr.ps1 -PathType Leaf) -eq $true) {
		Write-Host 'Update OK' -ForegroundColor Green
	}

	if((Test-Path -Path "$installationRoot\font\*" -PathType Leaf) -eq $true) {
		Write-Host 'Installing patched fonts' -ForegroundColor Yellow
		$objShell = New-Object -ComObject Shell.Application
		$objFolder = $objShell.Namespace(0x14)

		$Fonts = Get-ChildItem -Path "$installationRoot/font" -Recurse -Include *.ttf,*.otf
		foreach ($File in $Fonts) {
			$objFolder.CopyHere($File.fullname)
		}
	}
	else {
		Write-Host 'Required fonts not found' -BackgroundColor Red -ForegroundColor Yellow
	}

	Write-Host 'Installing PS profile'
	
	if((Test-Path $PROFILE -PathType Leaf -ErrorAction SilentlyContinue) -eq $true) {
		Copy-Item -Path $profileDir -Include Microsoft.*.ps1 -Destination $PROFILE"_backup" -Force
	}

	if((Test-Path $profileDir -PathType Container -ErrorAction SilentlyContinue) -eq $false) {
		mkdir $profileDir -ErrorAction Stop		
	}

	Copy-Item -Path $installationRoot\profile\Microsoft.PowerShell_profile.ps1 -Destination $PROFILE -Force -ErrorAction Stop

	Write-Host "Installing script sources..."

	if((Test-Path "$profileDir\profiled" -PathType Container -ErrorAction SilentlyContinue) -eq $false) {
		mkdir ($profileDir+'\profiled') -ErrorAction Stop
	}

	Copy-Item -Path "$installationRoot\profiled\*" -Include '*.ps1' -Destination "$profileDir\profiled" -Force -Recurse -ErrorAction Stop

	if((Test-Path -Path "$profileDir\profiled\0100.Set-Aliases.ps1" -PathType Leaf -ErrorAction SilentlyContinue) -eq $true) {
		Write-Host "Script sources installed OK" -ForegroundColor Green
	}

	[string]$start = (Read-Host 'Open new console to apply changes? (Y/N) :')
	if($start.ToLowerInvariant() -eq 'y' -or $start.ToLowerInvariant() -eq 'yes') {
		Start-Process powershell
	}
}