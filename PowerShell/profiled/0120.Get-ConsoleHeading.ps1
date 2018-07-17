function Get-ConsoleHeading () {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$false)][switch]$UsePredefinedRouletteValues=$true,
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)][string[]]$RouletteValues
    )

    [string[]]$titleRoulette = (
        'xtr v1.0',
        'destiny.games',
        'the abyss',
        'choose your destiny',
        '#release'
        )

    if (-not $UsePredefinedRouletteValues) {
        $titleRoulette = $RouletteValues
    }

    [int]$chosenIndex = Get-Random -Minimum 0 -Maximum $titleRoulette.Count

    return $titleRoulette[$chosenIndex]
}