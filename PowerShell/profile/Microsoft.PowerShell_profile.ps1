#INPUT PARAMS

param(
    [Parameter(Mandatory=$false)][switch]$StageConsole=$true,
    [Parameter(Mandatory=$false)][switch]$DetailedOutput=$false
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

cd \
clear

letters -InputText 'XTR v1.0' -ForegroundColor Green -ErrorAction SilentlyContinue
$Host.UI.RawUI.WindowTitle = 'XTR v1.0'
