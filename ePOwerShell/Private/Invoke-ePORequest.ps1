<#
.SYNOPSIS

    Builds the request URL to the ePO server, and calls Invoke-ePOwerShellWebClient with the URL query

.PARAMETER Name

    Specifies the function name to be used

.PARAMETER Query

    Specifies the query parameters to be used against the ePO server

.PARAMETER PassThru

    If specified, returns the raw content from the ePO server. Otherwise, returns the content as a hashtable

.PARAMETER BlockSelfSignedCerts

    By default, the script allows self signed certs applied to your ePO server. Specifying this flag will block self signed certs
#>

function Invoke-ePORequest {
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
            [void]$Query.Add(':output', 'terse')
        }
    } else {
        if (-not ($Query.':output' -eq 'json')) {
            [void]$Query.Add(':output', 'json')
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
        [void]$qs.Add("$($q.Name)=$($q.Value)")
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
