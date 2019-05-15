<#
    .SYNOPSIS
        Required command. Sets the necessary parameters to successfully communicate with an ePO server

    .DESCRIPTION
        This function sets up all information necessary to communicate with your ePO server.

        There are three ways to utilize this command: By manually specifying the variables each time you
        load the module, saving a json file on your computer with the necessary information, or saving the
        json as an environment variable, $env:ePOwerShell.

    .EXAMPLE
        Set ePO config after reading settings from an Environment variable
        ```powershell
        $env:ePOwerShell = @{
            Server      = 'My-ePO-Server.domain.com'
            Port        = 1234
            Credentials = (Get-Credential)
        }

        Set-ePOConfig
        ```
    .EXAMPLE
        Set ePO config by manually specifying values each time
        ```powershell
        Set-ePOConfig -Server 'My-ePO-Server.domain.com' -Port 1234 -Credentials (Get-Credential)
        ```
#>

function Set-ePOConfig {
    [CmdletBinding(DefaultParameterSetName = 'Env', SupportsShouldProcess = $True)]
    [Alias('Set-ePOServer')]
    param (
        <#
            .PARAMETER Server
                URL to the ePO server
        #>
        [Parameter(Mandatory = $True, ParameterSetName = 'ManualEntry')]
        [String]
        $Server,

        <#
            .PARAMETER Credentials
                Credentials with access to the ePO server
        #>
        [Parameter(Mandatory = $True, ParameterSetName = 'ManualEntry')]
        [System.Management.Automation.PSCredential]
        $Credentials,

        <#
            .PARAMETER Port
                Specifies the port necessary to communicate with the ePO server
        #>
        [Parameter(Mandatory = $False, ParameterSetName = 'ManualEntry')]
        [Int]
        $Port,

        <#
            .PARAMETER ePOwerShellSettings
                Specifies a path to a json containing all information necessary to connect to an ePO server
        #>
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
                TypeName     = 'System.Management.Automation.PSCredential'
                ArgumentList = @(
                    $Settings.Username,
                    ($Settings.Password | ConvertTo-SecureString)
                )
            }

            $Credentials = New-Object @GetCredentials

            $ePOwerShellVariables = @{
                Server      = $Settings.Server
                Credentials = $Credentials
            }

            if ($settings.Port) {
                [void]$ePOwerShellVariables.Add("Port", $Settings.Port)
            }
        }
        'ManualEntry' {
            $ePOwerShellVariables = @{
                Server      = $Server
                Credentials = $Credentials
            }

            if ($Port) {
                [void]$ePOwerShellVariables.Add("Port", $Port)
            }
        }
    }

    Write-Debug "Variables: $($ePOwerShellVariables | Out-String)"

    if ($PSCmdlet.ShouldProcess("Settings ePOwerShell configurations successfully")) {
        Initialize-ePOConfig @ePOwerShellVariables
    }
}