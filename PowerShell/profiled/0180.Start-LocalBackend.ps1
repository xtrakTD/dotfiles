function Start-LocalBackend {
    [CmdletBinding()]
    param (
        # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
        # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
        # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
        # characters as escape sequences.
        [Parameter(Mandatory=$false,                   
                   ValueFromPipeline=$false,
                   HelpMessage="Literal path to one or more locations.")]            
        [string]
        $BackEndRoot,
        
        # Specifies whether to update repo before launch
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$false,
                   HelpMessage="Specifies whether to update repo before launch")]                         
        [bool]
        $UpdateRepo=$false,

        # Specifies whether to stash or discard current changes
        # Only valid if $UpdateRepo is set to $true
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$false,
                   HelpMessage="Set to true if you want to stash local changes before git update")]
        [bool]
        $StashLocal=$false,

        # Specifies the name of branch to pull
        # Only valid if $UpdateRepo is set to $true
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$false,
                   HelpMessage="Set the name of the branch to pull"
        )]
        [string]
        $GitBranch,
        
        # Specifies whether to rebuild backend images
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$false,
                   HelpMessage="Set to true to run rebuild script")]
        [bool]
        $RebuildBackend=$false,

        # Specifies whether to delete Docker images before rebuild
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$false,
                   HelpMessage="Set to true to run Docker cleanup")]
        [bool]
        $RunCleanup=$false
    )
    
    begin {
        if ($BackEndRoot -eq '' -or $BackEndRoot -eq $null) {
            $BackEndRoot = (Join-Path -Path $BaseRepoPath -ChildPath 'backend')
        }
        if ($UpdateRepo -and !($GitBranch -eq $null -or $GitBranch -eq '')) {
            if(!($GitBranch -match '^(([B|b]ugfix)|([F|f]eature)|([R|r]elease)|(master)|(dev))\/?(.+)?$')) {
                Write-Host "Branch name [$GitBranch] is invalid" -ForegroundColor Red -BackgroundColor White
                $UpdateRepo = $false                                
            }
        }
        if ($RunCleanup) {
            $RebuildBackend=$true
        }

        Write-Host "Checking docker service ..."

        $DockerService = (Get-WmiObject -Class win32_service -Filter 'Name like "%docker%"')
        if ($DockerService.GetType().Name -eq 'ManagementObject') {
            if (-not ($DockerService.Started)) {
                Write-Host "Docker service not started...Trying to start" -BackgroundColor Yellow -ForegroundColor Red
                Start-Service $DockerService.Name
            }
        }
        elseif ($DockerService.GetType().FullName -eq 'System.Object[]') {
            $DockerService | % {
                if (-not ($_.Started)) {
                    Write-Host "Starting service [$($_.Name)]"
                    Start-Service $_.Name
                }
            }
        }
        else {
            Write-Error "Invalid object type or docker not installed"            
        }        
    }
    
    process {

        if((Test-Path -Path $BackEndRoot\app) -eq $false) {
            Write-Error "[$BackEndRoot] doens't contain [app] folder"
        }
        else {
            Set-Location -Path $BackEndRoot

            if ($UpdateRepo) {
                if ((Test-Path -Path .\.git) -eq $false) {
                    Write-Error 'Not a GIT repository!'
                }
                else {
                    if ($StashLocal) {
                        git stash
                    }
        
                    git pull origin $GitBranch
                    git checkout $GitBranch    
                }            
            }

            if ($RunCleanup) {
                Run-DockerCleanup
            }
    
            if ($RebuildBackend) {
                bash .\xtr_rebuild.sh
            }
            else {
                bash .\xtr_run.sh
            }
        }                
    }
}