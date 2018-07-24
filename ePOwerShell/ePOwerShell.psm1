<#
    .Synopsis

        This is the main scaffolding the glues all the pieces together.
#>
$public = @( Get-ChildItem -Path "${PSScriptRoot}\Public\*.ps1" -ErrorAction SilentlyContinue )
$private = @( Get-ChildItem -Path "${PSScriptRoot}\Private\*.ps1" -ErrorAction SilentlyContinue )

foreach ($import in @($public + $private)) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error -Message "Failed to import function: $($import.FullName): $_"
    }
}

Export-ModuleMember -Function $Public.BaseName
