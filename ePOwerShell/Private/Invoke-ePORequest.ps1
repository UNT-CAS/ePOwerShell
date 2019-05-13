<#
    .SYNOPSIS
        Builds the request URL to the ePO server, executes the API call, and returns values.
#>

function Invoke-ePORequest {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        <#
            .PARAMETER Name
                Specifies the function name to be used
        #>
        [String]
        $Name,

        <#
            .PARAMETER Query
                Specifies the query parameters to be used against the ePO server
        #>
        [Hashtable]
        $Query = @{}
    )

    if (-not ($Script:ePOwerShell)) {
        try {
            Set-ePOConfig
        } catch {
            Throw [System.Management.Automation.ParameterBindingException] 'ePO Server is not configured yet. Run Set-ePOwerShellServer first!'
        }
    }

    if (-not ($Query.':output' -eq 'json')) {
        [Void] $Query.Add(':output', 'json')
    }

    $URL = '{0}:{1}/remote/{2}' -f $ePOwerShell.Server, $ePOwerShell.Port, $Name

    [System.Collections.ArrayList] $QueryString = @()

    foreach ($Item in $Query.GetEnumerator()) {
        [Void] $QueryString.Add("$($Item.Name)=$($Item.Value)")
    }

    $RequestUrl = ('{0}?{1}' -f $Url, ($QueryString -join '&'))

    Write-Verbose ('Request URL: {0}' -f $RequestUrl)

    if (-not ([Net.ServicePointManager]::SecurityProtocol -eq 'Tls12')) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor
            [Net.SecurityProtocolType]::Tls12
    }

    $InvokeWebRequest = @{
        Uri = $RequestUrl
        Credential = $ePOwerShell.Credentials
        UseBasicParsing = $True
        ErrorAction = 'Stop'
    }

    if ($PSVersionTable.PSVersion.Major -le 5) {
        Write-Verbose 'PSVersion is -le 5'
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
    } else {
        Write-Verbose 'PSVersion is -gt 5'
        [Void] $InvokeWebRequest.Add('SkipCertificateCheck', $True)
    }

    Write-Verbose ('Request: {0}' -f ($InvokeWebRequest | ConvertTo-Json))

    try {
        $Response = Invoke-WebRequest @InvokeWebRequest
    } catch {
        Write-Information $_ -Tags Exception
        Throw $_
    }

    Write-Debug "Response: $($Response | Out-String)"

    if (-not ($Response.Content.StartsWith('OK:'))) {
        Throw $Response
    }

    Write-Output ($Response.Content.Substring(3).Trim() | ConvertFrom-Json)
}