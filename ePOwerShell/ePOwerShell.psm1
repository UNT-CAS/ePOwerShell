<#
    .Synopsis

        This is the main scaffolding the glues all the pieces together.
#>

$Class = Get-ChildItem -Path "${PSScriptRoot}\Classes\*.ps1" -ErrorAction SilentlyContinue
$Public = Get-ChildItem -Path "${PSScriptRoot}\Public\*.ps1" -ErrorAction SilentlyContinue
$Private = Get-ChildItem -Path "${PSScriptRoot}\Private\*.ps1" -ErrorAction SilentlyContinue

foreach ($Import in @($Class + $Public + $Private)) {
    Write-Verbose "Dot-sourcing '$($Import.Name)'"
    try {
        . $Import.FullName
    } catch {
        Write-Error -Message "Failed to import function: $($Import.FullName): $_"
    }
}

Export-ModuleMember -Function $Public.BaseName