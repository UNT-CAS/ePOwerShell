[System.String]    $ProjectDirectoryName = 'ePOwerShell'
[IO.FileInfo]      $PesterFile           = [IO.FileInfo] ([System.String] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[IO.DirectoryInfo] $ProjectRoot          = Split-Path -Parent $PesterFile.Directory

while (-not ($ProjectRoot.Name -eq $ProjectDirectoryName)) {
    $ProjectRoot = Split-Path -Parent $ProjectRoot.FullName
}

[IO.DirectoryInfo] $PublicFolder         = Join-Path -Path (Join-Path $ProjectRoot.FullName -ChildPath $ProjectDirectoryName -Resolve) -ChildPath 'Public' -Resolve

$global:Functions = (Get-ChildItem $PublicFolder.FullName -Filter '*.ps1' | Select-Object -ExpandProperty Name).Replace('.ps1', '')
$global:ExportedFunctions = ((Get-Module 'ePOwerShell').ExportedFunctions).GetEnumerator() | Select-Object -ExpandProperty Key

InModuleScope ePOwerShell {
    Context 'Module exports all functions' {
        foreach ($Function in $Functions) {
            It ('Exported {0}' -f $Function) {
                $Function | Should BeIn $ExportedFunctions
            }
        }
    }
}

Remove-Variable -Name Functions -Scope Global
Remove-Variable -Name ExportedFunctions -Scope Global