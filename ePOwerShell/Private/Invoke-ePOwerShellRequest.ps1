function Invoke-ePOwerShellRequest {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [String]
        $Name,

        [Hashtable]
        $Query,

        [Switch]
        $SkipOutput,

        [System.Net.WebClient]
        $WebClient = (New-Object System.Net.WebClient)
    )

    begin {
        if (-not ($ePOwerShell)) {
            Throw [System.Management.Automation.ParameterBindingException] 'ePO Server is not configured yet. Run Set-ePOwerShellServer first!'
        }

        if (-not ($ePOwerShell.Output)) {
            Write-Host 'Output not set. Defualting to Json'
            $ePOwerShell.Output = 'json'
        }

        if (-not ($SkipOutput)) {
            if (-not ($Query)) {
                $Query = @{
                    ':output' = $ePOwerShell.Output
                }
            } elseif (-not ($Query.ContainsKey(':Output'))) {
                $Query.Add(':output', $ePOwerShell.Output)
            }
        }

        # Force TLS 1.2
        if (-not ([Net.ServicePointManager]::SecurityProtocol -eq 'Tls12')) {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        }

add-type @"
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

        if ($Query) {
            [System.Collections.ArrayList] $qs = @()
            foreach ($q in $Query.GetEnumerator()) {
                $qs.Add("$($q.Name)=$($q.Value)")
            }
            $query_string = $qs -join '&'

            $RequestUrl = ('{0}?{1}' -f $Url, $query_string)
        } else {
            $RequestUrl = $URL
        }

        try {
            $response = $WebClient.DownloadString($RequestUrl)
        } catch [System.Security.Authentication.AuthenticationException] {
            Throw [System.Security.Authentication.AuthenticationException] ('Failed to authenticate to ePO server [{0}]: {1}' -f $ePOwerShell.Server, $_.Exception.Message)
        } catch {
            Throw ('Failed with unknown error: {0}' -f $_.Exception.Message)
        }

        if (-not ($response.StartsWith('OK:'))) {
            Throw $response
        }
    }

    end {
        if ($Query.':output' -eq 'json') {
            return ($response.SubString(3).Trim() | ConvertFrom-Json)
        } elseif ($Query.':output' -eq 'xml') {
            return ([xml]($response.Substring(3).Trim()))
        } else {
            return $response
        }
    }
}