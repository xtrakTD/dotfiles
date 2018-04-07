
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force -ErrorAction SilentlyContinue

Test-Administrator -ErrorAction Continue | Out-Null

if($DetailedOutput)
{
    $DebugPreference='Continue' 
    $VerbosePreference='Continue'
    $InformationPreference='Continue'
}

$ErrorView='NormalView'

[string]$CredentialsPath="$env:USERPROFILE\.creds"

if(-not (Test-Path -Path $CredentialsPath -PathType Container))
{
    try
    {
        New-Item -Path $env:USERPROFILE -Name .creds -Force -ItemType Directory
    }
    catch
    {
        Write-Error $Error[0].ToString() -ErrorAction:Continue
        $CredentialsPath = $env:USERPROFILE
    }
}

if(-not (Test-Path $env:USERPROFILE\.psreadline -PathType Container))
{
    New-Item -Path $env:USERPROFILE -Name .psreadline -ItemType Directory
}
