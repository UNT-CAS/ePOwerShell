function Get-ePOwerShellServer {
    [CmdletBinding()]
    [Alias('Get-ePOServer')]
    param ()

    process {
        if (-not ($Script:ePOwerShell)) {
            Throw [System.Management.Automation.ParameterBindingException] 'ePO Server is not configured yet. Run Set-ePOwerShellServer first!'
        }
        
        $ePOwerShellVariables = @{
            Port        = $Script:ePOwerShell.Port
            Server      = $Script:ePOwerShell.Server
            Credentials = $Script:ePOwerShell.Credentials
        }
    }

    end {
        return $ePOwerShellVariables
    }
}