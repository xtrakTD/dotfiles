function Start-LocalFrontend {
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
        $FrontEndRoot,
        
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
        $GitBranch            
    )
    
    begin {
        if ($FrontEndRoot -eq '' -or $FrontEndRoot -eq $null) {
            $FrontEndRoot = (Join-Path -Path $BaseRepoPath -ChildPath 'frontend')
        }
        if ($UpdateRepo -and !($GitBranch -eq $null -or $GitBranch -eq '')) {
            if(!($GitBranch -match '^(([B|b]ugfix)|([F|f]eature)|([R|r]elease)|(master)|(dev))\/?(.+)?$')) {
                Write-Host "Branch name [$GitBranch] is invalid" -ForegroundColor Red -BackgroundColor White
                $UpdateRepo = $false                                
            }
        }
    }
    
    process {

        if((Test-Path -Path $FrontEndRoot\src) -eq $false) {
            Write-Error "[$FrontEndRoot] doens't contain [src] folder"
        }
        else {
            Set-Location -Path $FrontEndRoot

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
    
            yarn
            yarn livereload
        }                
    }
}