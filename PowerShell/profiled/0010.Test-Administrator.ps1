Function Test-Administrator 
{
    [CmdletBinding()]
    param()

    $tempuser = [Security.Principal.WindowsIdentity]::GetCurrent();
    $isAdmin = (New-Object Security.Principal.WindowsPrincipal $tempuser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    
    Set-Variable -Name IsAdminSession -Value $IsAdmin -Scope Global

    return $isAdmin
}