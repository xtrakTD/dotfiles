function Run-DockerCleanup {
    [CmdletBinding()]
    param (        
    )
    
    Write-Host 'Cleaning up Docker trash ' -ForegroundColor Red -BackgroundColor Yellow

    docker container rm $(docker ps -aq) -f
    docker image rm $(docker image ls -aq)
    docker volume rm $(docker volume ls -q)    

    Write-Host 'DONE' -ForegroundColor Black -BackgroundColor White
}