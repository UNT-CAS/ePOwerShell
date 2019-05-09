function Invoke-ePOWakeUpAgent {
    [CmdletBinding()]
    [Alias('Invoke-ePOwerShellWakeUpAgent', 'Invoke-ePOWakeUpAgent')]
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        $ComputerName,

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

    process {
        try {
            foreach ($Computer in $ComputerName) {
                if ($Computer -is [ePOComputer]) {
                    Write-Verbose "Computer was pipelined with an ePOComputer object"
                    $ePOComputer = $Computer
                } else {
                    Write-Verbose "Confirming computer is in ePO: $Computer"

                    if (-not ($ePOComputer = Get-ePOComputer -Computer $Computer)) {
                        Write-Error ("Failed to find computer system '{0}' in ePO" -f $Computer) -ErrorAction Stop
                        continue
                    }
                }

                Write-Verbose ('Found computer system in ePO: {0}' -f ($ePOComputer | Out-String))

                if (-not ($ePOComputer.ManagedState)) {
                    Write-Error ('Computer System is not in a managed state: {0}' -f $Computer) -ErrorAction Stop
                    continue
                }

                Write-Verbose ('Computer System is in a managed state: {0}' -f $Computer)

                $Request = @{
                    Name     = 'system.wakeupAgent'
                    Query    = @{
                        names = $ePOComputer.ComputerName
                        fullProps = $FullProps
                        forceFullPolicyUpdate = $ForceFullPolicyUpdate
                        abortAfterMinutes = $AbortAfter
                        retryIntervalSeconds = $RetryIntervalSeconds
                        attempts = $NumberOfAttempts
                        randomMinutes = $RandomMinutes
                        superAgent = $SuperAgent
                    }
                }

                Write-Verbose "Request: $($Request | ConvertTo-Json)"
                $Response = Invoke-ePORequest @Request
                Write-Debug "Response: $($Response | Format-Table)"

                $Results = @{}
                $Response.Split('\n') | Where-Object { $_ } | ForEach-Object { $s = $_.Split(':'); $Results.Add($s[0].Trim(), $s[1].Trim()) }
                $Response.Split("`n") | ForEach-Object { $s = $_.Split(':'); $Results.Add($s[0].Trim(), $s[1].Trim()) }
                $ResultsObject = New-Object PSObject -Property $Results

                if ([Boolean]$Results.Completed) {
                    Write-Verbose ('Successfully woke up {0}' -f $ePOComputer.ComputerName) 
                } elseif ([Boolean]$Results.Failed) {
                    Write-Error ('Failed to wake up {0}' -f $ePOComputer.ComputerName) -ErrorAction Stop
                } elseif ([Boolean]$Results.Expired) {
                    Write-Error ('Failed to wake up {0}. Session expired.' -f $ePOComputer.ComputerName) -ErrorAction Stop
                } else {
                    Write-Error ('Failed to wake up {0}. Unknown error' -f $ePOComputer.ComputerName) -ErrorAction Stop
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }
}