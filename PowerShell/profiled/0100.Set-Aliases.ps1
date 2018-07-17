Set-Alias -Name connect -Value New-RemotePSSession -Option AllScope -Force
Set-Alias -Name ls -Value Get-ChildItemColorFormatWide -Option AllScope -Force
Set-Alias -Name dir -Value Get-ChildItemColor -Option AllScope -Force
Set-Alias -Name eps -Value Enter-PSSession -Option AllScope -Force
Set-Alias -Name sublime -Value 'C:\Program Files\Sublime Text 3\sublime_text.exe' -Option AllScope -Force
Set-Alias -Name edit -Value sublime -Option AllScope -Force
Set-Alias -Name recycle -Value Recycle-IISAppPools -Option AllScope -Force
Set-Alias -Name letters -Value Write-Ascii -Option AllScope
Set-Alias -Name picture -Value Convert-ToPSArt -Option AllScope
Set-Alias -Name bash -Value "$env:GIT_INSTALL_ROOT\bin\bash.exe" -Option AllScope -Force
