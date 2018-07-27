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

        [System.Net.WebClient]
        $WebClient = (New-Object System.Net.WebClient)
    )

    begin {
        if (-not ($Script:ePOwerShell)) {
            Throw [System.Management.Automation.ParameterBindingException] 'ePO Server is not configured yet. Run Set-ePOwerShellServer first!'
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

        # Force TLS 1.2
        if (-not ([Net.ServicePointManager]::SecurityProtocol -eq 'Tls12')) {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        }

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

        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ePOwerShell.Credentials.Password)
        $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        $WebClient.Credentials = New-Object System.Net.NetworkCredential -ArgumentList @($ePOwerShell.Credentials.Username, $UnsecurePassword)
    }

    process {
        $URL = "$($ePOwerShell.Server):$($ePOwerShell.Port)/remote/${Name}"

        [System.Collections.ArrayList] $qs = @()
        foreach ($q in $Query.GetEnumerator()) {
            $qs.Add("$($q.Name)=$($q.Value)") | Out-Null
        }
        $query_string = $qs -join '&'

        $RequestUrl = ('{0}?{1}' -f $Url, $query_string)

        Write-Debug "Request Url: $RequestUrl"
        try {
            $Response = $WebClient.DownloadString($RequestUrl)
        } catch [System.Security.Authentication.AuthenticationException] {
            Throw [System.Security.Authentication.AuthenticationException] ('Failed to authenticate to ePO server [{0}]: {1}' -f $ePOwerShell.Server, $_.Exception.Message)
        } catch {
            Throw ('Failed with unknown error: {0}' -f $_.Exception.Message)
        }

        Write-Debug "Response: $($Response | Out-String)"
        if (-not ($Response.StartsWith('OK:'))) {
            Throw $Response
        }
    }

    end {
        $Response = $Response.Substring(3).Trim()

        if ($PassThru) {
            return $Response
        } else {
            return ($Response | ConvertFrom-Json)
        }
    }
}