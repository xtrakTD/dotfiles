function Get-AllEC2Instances {
    [CmdletBinding()]
    param (
        
    )
    
    if((Get-AWSCredential) -ne $null) {
        ((Get-AWSRegion).Region | % { Get-EC2Instance -Region $_ }).Instances
    }
    else {
        Write-Host 'No AWS Credential found' -BackgroundColor Yellow -ForegroundColor Red
    }
}