<#
    .SYNOPSIS
        Saves the stored ePOwerShell settings to your environment for future use

    .DESCRIPTION
        Rather than typing in your credentials to ePOwerShell anytime you open your shell, you can store
        the current configuration as a json object in your user environment for for future use. This does
        require `Set-ePOConfig` to be run first.

    .EXAMPLE
        Set and store ePOwerShell settings
        ```powershell
        PS> $env:ePOwerShell = @{
                Server               = 'My-ePO-Server.domain.com'
                Port                 = 1234
                Credentials          = (Get-Credential)
                AllowSelfSignedCerts = $True
            }
        PS> Set-ePOConfig
        PS> Save-ePOConfig
        PS>
        ```
#>

function Save-ePOConfig {
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = "High")]
    param ()

    try {
        if (-not ($script:ePOwerShell)) {
            Throw "`$ePOwerShell is not currently set. Run `Set-ePOConfig` first and try again."
        }

        $Save = @{
            Server               = $script:ePOwerShell.Server
            Port                 = $script:ePOwerShell.Port
            Username             = $script:ePOwerShell.Credentials.Username
            Password             = ($script:ePOwerShell.Credentials.Password | ConvertFrom-SecureString)
            AllowSelfSignedCerts = $script:ePOwerShell.AllowSelfSignedCerts
        }

        if ($PSCmdlet.ShouldProcess("Saving ePOwerShell configurations")) {
            [Environment]::SetEnvironmentVariable("ePOwerShell", ($Save | ConvertTo-Json -Compress), "User")
        }
    } catch {
        Write-Information $_ -Tags Exception
    }
}

Export-ModuleMember -Function 'Save-ePOConfig'