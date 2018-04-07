[Void][Reflection.Assembly]::LoadWithPartialName("System.Collections.Generic")
[Void][Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")

Import-Module PowerShellGet -ErrorAction Stop

if ($StageConsole) 
{
	if (-not ((ping.exe scom.stage.stage -n 1) -match "^(.+)?could\snot\sfind\shost\s(.+)$")) 
	{
		if($DetailedOutput)
    {
        Import-Module \\scom.stage.stage\heart\Infrastructure.stage$\Scripts\Deploy.stage\StageDeploy.psm1 -Verbose -ErrorAction Continue
    }
    else
    {
        Import-Module \\scom.stage.stage\heart\Infrastructure.stage$\Scripts\Deploy.stage\StageDeploy.psm1 -ErrorAction SilentlyContinue | Out-Null
    }
  }
  else 
  {
    Write-Warning 'Unable to ping host [scom.stage.stage]' -WarningAction:Continue
  }    
}

if((Get-Command Get-ChildItemColor -ErrorAction SilentlyContinue) -eq $null)
{
    Install-Module Get-ChildItemColor -Scope CurrentUser -Force
}
else 
{
    Import-Module Get-ChildItemColor -ErrorAction Continue -Force
}

if((Test-Administrator) -eq $true)
{
    Import-Module WebAdministration -ErrorAction Continue -Force
}

if((Get-Command pshazz -ErrorAction SilentlyContinue) -eq $null)
{
    Install-ThemeEngine -ErrorAction Stop
}

Import-Module PSReadLine

Set-PSReadlineOption -HistorySavePath $env:USERPROFILE\.psreadline\history.txt

Import-Module Write-Ascii -ErrorAction Continue -Force    
