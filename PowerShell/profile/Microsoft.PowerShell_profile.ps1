#INPUT PARAMS

param(
    [Parameter(Mandatory=$false)][switch]$StageConsole=$false,
    [Parameter(Mandatory=$false)][switch]$DetailedOutput=$true
)

$profilePath = $PROFILE.Replace(($PROFILE.Split('\')[$PROFILE.Split('\').Count - 1]), '')
cd $profilePath

$scripts = (Get-ChildItem -Path .\profiled\ -Include *.ps* -Recurse -Force).Name
cd .\profiled

$scripts | %{ 
    Write-Host "Sourcing script [ " -NoNewline
	Write-Host $_ -ForegroundColor White -NoNewline 
	Write-Host " ]"     
	. ".\$_"
}

Set-XtrPSHazzTheme

cd $env:USERPROFILE
clear

# letters -InputText 'XTR v1.0' -ForegroundColor Green -ErrorAction SilentlyContinue
letters -InputText (Get-ConsoleHeading) -ForegroundColor Green -ErrorAction SilentlyContinue
$Host.UI.RawUI.WindowTitle = 'XTR v1.0'
