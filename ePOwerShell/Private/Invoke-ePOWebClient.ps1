<#
.SYNOPSIS

    Communicates with the ePO server and returns its response

.PARAMETER URL

    Called only from Invoke-ePOwerSehllRequest, this parameter specifies the
    formatted query URL to the ePO server.
#>

function Invoke-ePOwerShellWebClient {
    param (
        [Parameter(Position = 1, Mandatory = $True)]
        [String]
        $URL,

        [System.Net.WebClient]
        $WebClient = (New-Object System.Net.WebClient)
    )

    # Force TLS 1.2
    if (-not ([Net.ServicePointManager]::SecurityProtocol -eq 'Tls12')) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor
            [Net.SecurityProtocolType]::Tls12
    }

    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ePOwerShell.Credentials.Password)
    $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $WebClient.Credentials = New-Object System.Net.NetworkCredential -ArgumentList @($ePOwerShell.Credentials.Username, $UnsecurePassword)

    try {
        $Response = $WebClient.DownloadString($URL)
    } catch [System.Security.Authentication.AuthenticationException] {
        Throw [System.Security.Authentication.AuthenticationException] ('Failed to authenticate to ePO server [{0}]: {1}' -f $ePOwerShell.Server, $_.Exception.Message)
    } catch {
        Throw ('Failed with unknown error: {0}' -f $_.Exception.Message)
    }

    return $Response
}