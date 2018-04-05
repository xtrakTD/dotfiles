Function Install-ThemeEngine
{
    [CmdletBinding()]
    param()
    
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    
    if((Get-Command scoop -ErrorAction SilentlyContinue) -eq $null)
    {
        Invoke-Expression(New-Object Net.Webclient).DownloadString('https://get.scoop.sh')
    }

    scoop install git pshazz

    if((Get-Command pshazz -ErrorAction SilentlyContinue) -eq $null)
    {
        Write-Error 'Something went wrong during PSHazz installation. Try again later' -ErrorAction Continue
    }          
}