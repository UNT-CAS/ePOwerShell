#Requires -Version 5.0
class ePO {
    [string]                $ePO_Server = $Null
    [string]                $Username = $Null
    [SecureString]          $Password = $Null
    [System.Net.WebClient]  $WebClient = (New-Object System.Net.WebClient)


    ePO() {
        $settings = Resolve-Path 'settings.json' -ErrorAction Stop
        $settings = ConvertFrom-Json (Get-Content $settings | Out-String)

        $this.ePO_Server = 'https://{0}:{1}' -f @($settings.api.server, $settings.api.port)
        $this.Username = $settings.api.username
        $this.Password = ConvertTo-SecureString -String $settings.api.password -AsPlainText -Force

        $this.Connect()
    }


    ePO([string] $settings_json_path) {
        $settings = Resolve-Path $settings_json_path -ErrorAction Stop
        $settings = ConvertFrom-Json (Get-Content $settings | Out-String)

        $this.ePO_Server = 'https://{0}:{1}' -f @($settings.api.server, $settings.api.port)
        $this.Username = $settings.api.username
        $this.Password = ConvertTo-SecureString $settings.api.password -AsPlainText -Force

        $this.Connect()
    }


    ePO([string] $ePO_Server, [string] $Username, [string] $Password) {
        $this.ePO_Server = $ePO_Server
        $this.Username = $Username
        $this.Password = ConvertTo-SecureString $Password -AsPlainText -Force

        $this.Connect()
    }

    
    [void] Connect() {
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.Password)
        $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        $this.WebClient.Credentials = New-Object System.Net.NetworkCredential -ArgumentList @($this.Username, $UnsecurePassword)
    }


    [PSCustomObject] Request([string] $Name) {
        $url = "$($this.epo_Server)/remote/${Name}"
        return $this.Request($Name, @{':output'='json'})
    }


    [PSCustomObject] Request([string] $Name, [hashtable] $Query) {
        if (-not $Query.ContainsKey(':output')) {
            $Query.Add(':output', 'json')
        }

        $url = "$($this.epo_Server)/remote/${Name}"
        [System.Collections.ArrayList] $qs = @()
        foreach ($q in $Query.GetEnumerator()) {
            $qs.Add("$($q.Name)=$($q.Value)")
        }
        $query_string = $qs -join '&'

        Write-Debug "${url}?${query_string}"
        $response = $this.WebClient.DownloadString("${url}?${query_string}")

        if (-not $response.StartsWith('OK:')) {
            Throw $response
        }

        return ConvertFrom-Json $response.Substring(3)
    }


    [PSCustomObject] SystemFind([string] $SearchText) {
        return $this.Request('system.find', @{'searchText'=$SearchText})
    }
}