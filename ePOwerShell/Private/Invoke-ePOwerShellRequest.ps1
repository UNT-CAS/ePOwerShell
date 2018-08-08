function Invoke-ePOwerShellRequest {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [String]
        $Name,

        [Hashtable]
        $Query = @{},

        [Switch]
        $PassThru,

        [Switch]
        $BlockSelfSignedCerts
    )

    if (-not ($Script:ePOwerShell)) {
        try {
            Set-ePOwerShellServer
        } catch {
            Throw [System.Management.Automation.ParameterBindingException] 'ePO Server is not configured yet. Run Set-ePOwerShellServer first!'
        }
    }

    if ($PassThru) {
        if (-not ($Query.':output' -eq 'terse')) {
            $Query.Add(':output', 'terse') | Out-Null
        }
    } else {
        if (-not ($Query.':output' -eq 'json')) {
            $Query.Add(':output', 'json') | Out-Null
        }
    }

    if ($BlockSelfSignedCerts) {
        Write-Debug 'Not allowing self signed certs'
    } else {
        Write-Debug 'Allowing self signed certs'

Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    }

    $URL = "$($ePOwerShell.Server):$($ePOwerShell.Port)/remote/${Name}"

    [System.Collections.ArrayList] $qs = @()
    foreach ($q in $Query.GetEnumerator()) {
        $qs.Add("$($q.Name)=$($q.Value)") | Out-Null
    }
    $query_string = $qs -join '&'

    $RequestUrl = ('{0}?{1}' -f $Url, $query_string)

    try {
        $Response = Invoke-ePOwerShellWebClient $RequestUrl
    } catch {
        Throw $_
    }

    Write-Debug "Response: $($Response | Out-String)"
    if (-not ($Response.StartsWith('OK:'))) {
        Throw $Response
    }

    $Response = $Response.Substring(3).Trim()

    if ($PassThru) {
        return $Response
    } else {
        return ($Response | ConvertFrom-Json)
    }
}