function Get-AllEC2InstanceStates {
    [CmdletBinding()]
    param (
        
    )
    
    if((Get-AWSCredential) -ne $null) {

        (Get-AWSRegion).Region | 
        % { Get-EC2Instance -Region $_ | 
            % {	 
                $_.RunningInstance | 
                % {
                    Write-Output $("Instance '{0}' State is '{1}'" -f $_.InstanceId, $_.State.Name)
                }
            }    
        }
    }
    else {
        Write-Host 'No AWS Credential found' -BackgroundColor Yellow -ForegroundColor Red
    }
}