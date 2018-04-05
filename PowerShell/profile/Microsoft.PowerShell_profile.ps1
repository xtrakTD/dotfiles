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
    write-host "Sourcing script [ " -NoNewline
	Write-Host $_ -ForegroundColor White -NoNewline 
	Write-Hose " ]"     
	. ".\$_"
}

Set-XtrPSHazzTheme

cd \
clear