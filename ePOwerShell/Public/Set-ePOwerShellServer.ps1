function Set-ePOwerShellServer {
    [CmdletBinding(DefaultParameterSetName = 'Env')]
    [Alias('Set-ePOServer')]
    param (
        [Parameter(Mandatory = $True, ParameterSetName = 'ManualEntry')]
        [String]
        $Server,

        [Parameter(Mandatory = $True, ParameterSetName = 'ManualEntry')]
        [Int]
        $Port,

        [Parameter(Mandatory = $True, ParameterSetName = 'ManualEntry')]
        [System.Management.Automation.PSCredential]
        $Credentials,

        [Parameter(ParameterSetName = 'Env')]
        [String]
        $ePOwerShellSettings = (${env:ePOwerShell})
    )

    Write-Debug "PSCmdlet.ParameterSetName: $($PSCmdlet.ParameterSetName)"
    Write-Debug "ePOwerShellSettings: $ePOwerShellSettings"
    if (
        (-not ($PSCmdLet.ParameterSetName -Contains 'ManualEntry')) -and
        (-not ($ePOwerShellSettings))
    ) {
        Throw "Unable to set ePOwerShell server information. Either set '`$env:ePOwerShell', or re-run the command and specify all necessary information"
    }
    Write-Debug "Found something"

    switch ($PSCmdLet.ParameterSetName) {
        'Env' {
            if (Test-Path $ePOwerShellSettings) {
                Write-Debug "This is a filepath too a json"
                Write-Debug "FilePath: $ePOwerShellSettings"
                try {
                    $Settings = Get-Content $ePOwerShellSettings | Out-String | ConvertFrom-Json
                } catch {
                    Throw "Failed to import existing Json: $($_.Exception)"
                }
            } else {
                Write-Debug "This is a stored json in env"
                try {
                    $Settings = $ePOwerShellSettings | ConvertFrom-Json
                } catch {
                    Throw "Failed to import existing Json: $($_.Exception)"
                }
            }

            Write-Debug "Settings: $($Settings | Out-String)"

            $GetCredentials = @{
                TypeName        = 'System.Management.Automation.PSCredential'
                ArgumentList    = @(
                    $Settings.Username,
                    ($Settings.Password | ConvertTo-SecureString)
                )
            }

            $Credentials = New-Object @GetCredentials

            $ePOwerShellVariables = @{
                Server      = $Settings.Server
                Port        = $Settings.Port
                Credentials = $Credentials
            }
        }
        'ManualEntry' {
            $ePOwerShellVariables = @{
                Server      = $Server
                Port        = $Port
                Credentials = $Credentials
            }
        }
    }

    Write-Debug "Variables: $($ePOwerShellVariables | Out-String)"

    Initialize-ePOwerShellVariables @ePOwerShellVariables
}