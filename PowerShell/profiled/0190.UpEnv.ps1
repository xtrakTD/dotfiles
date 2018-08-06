function UpEnv {
    [CmdletBinding()]
    param (
        # Backend path
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$false,
                   HelpMessage="Path to backend root")]
        [string]
        $BackendRoot,

        # Frontend path
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$false,
                   HelpMessage="Path to frontend root")]
        [string]
        $FrontendRoot,

        # Backend branch
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$false,
                   HelpMessage="Name of backend branch")]
        [string]
        $BackendBranch,

        # Frontend branch
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$false,
                   HelpMessage="Name of frontend branch")]
        [string]
        $FrontendBranch,

        # Update repo
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$false,
                   HelpMessage="Update repo")]
        [bool]
        $UpdateRepo=$false,
        
        # Run cleanup
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$false,
                   HelpMessage="Run cleanup")]
        [bool]
        $RunCleanup=$false
    )
    
    begin {
        if ($RunCleanup) {
            $UpdateRepo = $true
        }
    }
    
    process {
        if ($RunCleanup) {
            docker stop $(docker ps -q)
            Run-DockerCleanup
        }       

        $BackArgs = "Start-LocalBackend -UpdateRepo $([int]$UpdateRepo) "
        if ($BackendBranch.Length -gt 0) {
            $BackArgs += "-GitBranch $BackendBranch "
        }
        if ($BackendRoot.Length -gt 0) {
            $BackArgs += "-BackEndRoot $BackendRoot "
        }
        $BackArgs += "-RebuildBackend $([int]$RunCleanup) -StashLocal $([int]$UpdateRepo)"
                
        $FrontArgs = "Start-LocalFrontend -UpdateRepo $([int]$UpdateRepo) "
        if ($FrontendBranch.Length -gt 0) {
            $FrontArgs += "-GitBranch $FrontendBranch "
        }
        if ($FrontendRoot.Length -gt 0) {
            $FrontArgs += "-FrontEndRoot $FrontendRoot "
        }
        $FrontArgs += "-StashLocal $([int]$UpdateRepo)"

        Write-Host "Starting environment" -BackgroundColor DarkGray -ForegroundColor Yellow

        Write-Host "$BackArgs"
        Write-Host "$FrontArgs"
        
        if(Test-Administrator) {
            Start-Process powershell -ArgumentList "-command $BackArgs"

            [int]$SleepIter = 0
            while ($(curl -s localhost:8080/api/v1/web/me/status | jq -r .is_guest) -ne 'true' -and $SleepIter -lt 200) {
                Write-Host 'Waiting for backend...'
                Start-Sleep -Seconds 3
                $SleepIter++
            }

            if($(curl -s localhost:8080/api/v1/web/me/status | jq -r .is_guest) -eq 'true') {
                Write-Host "Backend UP" -ForegroundColor Green
                Write-Host "Killing powershell process..."

                $BackendProcess = (Get-WmiObject -Class win32_process | ?{ $_.Path -like '*powershell*' -and $_.CommandLine -like '*LocalBackEnd*' })
                Get-Process -PID $BackendProcess.ProcessId | Kill -Force

                Write-Host "Starting Frontend..." -ForegroundColor Yellow
                Start-Process powershell -ArgumentList " -command $FrontArgs"            
            }
            else {
                Write-Warning "Backend didn't start, won't proceed"
            }                                
        }
        else {
            Write-Error "Elevated console required to launch dev environment"
        }        
    }
}