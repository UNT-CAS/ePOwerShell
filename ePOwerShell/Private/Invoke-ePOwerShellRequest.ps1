function Invoke-ePOerShellRequest {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [String]
        $Name,

        [Hashtable]
        $Query,

        [String]
        $ePOwerShell = $env:ePOwerShell,

        [System.Net.WebClient]
        $WebClient = (New-Object System.Net.WebClient)
    )

    begin {
        if (-not ($ePOwerShell)) {
            Throw [System.Management.Automation.ParameterBindingException] 'Required Parameter (ePOwerShell) is not available'
        }
        
        $ePOwerShell = $ePOwerShell | ConvertFrom-Json

        if (-not ($ePOwerShell.Output)) {
            Write-Debug 'Output not set. Defualting to Json'
            $ePOwerShell.Output = 'json'
        }

        if (-not ($Query)) {
            $Query = @{
                ':output' = $ePOwerShell.Output
            }
        } elseif (-not ($Query.ContainsKey(':Output')) {
            $Query.Add(':output', $ePOwerShell.Output)
        }

        # Force TLS 1.2
        if (-not ([Net.ServicePointManager]::SecurityProtocol -eq 'Tls12')) {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        }

        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ePOwerShell.Password)
        $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        $WebClient.Credentials = New-Object System.Net.NetworkCredential -ArgumentList @($ePOwerShell.Username, $UnsecurePassword)
    }

    process {
        $URL = "$($ePOerShell.epo_Server)/remote/${Name}"
        [System.Collections.ArrayList] $qs = @()
        foreach ($q in $Query.GetEnumerator()) {
            $qs.Add("$($q.Name)=$($q.Value)")
        }
        $query_string = $qs -join '&'

        Write-Debug "${url}?${query_string}"
        $response = $WebClient.DownloadString("${URL}?${query_string}")

        if (-not $response.StartsWith('OK:')) {
            Throw $response
        }
    }

    end {
        if ($Query.':output' -eq 'json') {
            return ConvertFrom-Json $response.SubString(3).Trim()
        } elseif ($Query.':output' -eq 'xml') {
            return [xml]($response.Substring(3).Trim())
        } else {
            return $response
        }
    }
}