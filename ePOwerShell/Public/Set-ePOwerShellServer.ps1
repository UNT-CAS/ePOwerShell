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
        [ValidateSet("json", "xml", "terse", "verbose")]
        [String]
        $Output,

        [Parameter(Mandatory = $True, ParameterSetName = 'ManualEntry')]
        [System.Management.Automation.PSCredential]
        $Credentials,

        [Parameter(ParameterSetName = 'Env')]
        [String]
        $ePOwerShellSettings = (${env:ePOwerShell})
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName: $($PSCmdlet.ParameterSetName)"
        Write-Debug "ePOwerShellSettings: $ePOwerShellSettings"
        if (
            (-not ($PSCmdLet.ParameterSetName -Contains 'ManualEntry')) -and
            (-not ($ePOwerShellSettings))
        ) {
            Throw "Unable to set ePOwerShell server information. Either set '`$env:ePOwerShell', or re-run the command and specify all necessary information"
        }
        Write-Debug "Found something"
    }

    process {
        switch ($PSCmdLet.ParameterSetName) {
            'Env' {
                if (Test-Path $ePOwerShellSettings) {
                    Write-Debug "This is a filepath too a json"
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
                    ArgumentList   = @(
                        $Settings.Username,
                        ($Settings.Password | ConvertTo-SecureString)
                    )
                }

                $Credentials = New-Object @GetCredentials

                $ePOwerShellVariables = @{
                    Output      = $Settings.Output
                    Port        = $Settings.Port
                    Server      = $Settings.Server
                    Credentials = $Credentials
                }
            }
            'ManualEntry' {
                $ePOwerShellVariables = @{
                    Output      = $Output
                    Port        = $Port
                    Server      = $Server
                    Credentials = $Credentials
                }
            }
        }

        Write-Debug "Variables: $($ePOwerShellVariables | Out-String)"
    }

    end {
        Initialize-ePOwerShellVariables @ePOwerShellVariables
    }
}