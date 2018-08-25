function Invoke-ePOwerShellWakeUpAgent {
    [CmdletBinding()]
    [Alias('Invoke-ePOWakeUpAgent')]
    param (
        [Parameter(Mandatory = $True, Position = 1, ParameterSetName = 'ComputerName')]
        [String[]]
        $ComputerName,

        [Parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = 'ComputerObject')]
        [PSCustomObject[]]
        $ComputerObject,

        [Switch]
        $ForceFullPolicyUpdate,

        [Switch]
        $FullProps,

        [Switch]
        $SuperAgent,

        [int32]
        $AbortAfter = 5,
        
        [int32]
        $RetryIntervalSeconds = 30,

        [int32]
        $NumberOfAttempts = 1,
        
        [int32]
        $RandomMinutes = 0
    )

    begin {
        [System.Collections.ArrayList]$Computers = @()
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            "ComputerName" {
                $ComputerName = $ComputerName.Split(',').Trim()

                foreach ($Computer in $ComputerName) {
                    Write-Verbose "Confirming computer is in ePO: $Computer"

                    if (-not ($ePOComputer = Find-ePOwerShellComputerSystem -ComputerName $Computer)) {
                        Write-Warning ("Failed to find computer system '{0}' in ePO" -f $Computer)
                        continue
                    }

                    Write-Verbose ('Found computer system in ePO: {0}' -f ($ePOComputer | Out-String))

                    if (-not ($ePOComputer.ManagedState)) {
                        Write-Warning ('Computer System is not in a managed state: {0}' -f $Computer)
                        continue
                    }

                    Write-Verbose ('Computer System is in a managed state: {0}' -f $Computer)

                    [void]$Computers.Add($Computer)
                }
            }
            "ComputerObject" {
                foreach ($Computer in $ComputerObject) {
                    if (-not ($Computer.ManagedState)) {
                        Write-Warning ('Computer System is not in a managed state: {0}' -f $Computer.ComputerName)
                        continue
                    }
    
                    Write-Verbose ('Computer System is in a managed state: {0}' -f $Computer.ComputerName)
    
                    [void]$Computers.Add($Computer.ComputerName)
                }
            }
        }
    }

    end {
        if (-not ($Computers)) {
            Throw "Failed to find any computers in ePO to wake"
        }
    
        $Request = @{
            Name     = 'system.wakeupAgent'
            Query    = @{
                names = ($Computers -Join ',')
                fullProps = $FullProps
                forceFullPolicyUpdate = $ForceFullPolicyUpdate
                abortAfterMinutes = $AbortAfter
                retryIntervalSeconds = $RetryIntervalSeconds
                attempts = $NumberOfAttempts
                randomMinutes = $RandomMinutes
                superAgent = $SuperAgent
            }
        }
    
        Write-Debug "[Invoke-ePOwerShellWakeUpAgent] Request: $($Request | ConvertTo-Json)"
        $Response = Invoke-ePOwerShellRequest @Request
    
        Write-Debug "[Invoke-ePOwerShellWakeUpAgent] Response: $($Response | Out-String)"
    
        $Results = @{}
        $Response.Split("`n") | % { $s = $_.Split(':'); $Results.Add($s[0].Trim(), $s[1].Trim()) }
        $ResultsObject = New-Object PSObject -Property $Results
    
        if (-not ($ResultsObject.Completed -eq $Computers.Count)) {
            Throw ('Failed to wake the agents on {0} computers: {1}' -f $ResultsObject.failed, ($ResultsObject | Out-String))
        }
    
        Write-Verbose ('Successfully waked up the agents on {0} computers' -f $ResultsObject.Completed)
    }
}