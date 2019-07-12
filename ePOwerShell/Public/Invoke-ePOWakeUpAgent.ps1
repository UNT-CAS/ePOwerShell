<#
    .SYNOPSIS
        Wakes up the ePO Agent on specified computer

    .DESCRIPTION
        For each specified computer, the ePO server attempts to wake up the computer's agent and run
        policy updates.

    .PARAMETER Computer
        Specifies the computer(s) to waking up. Can be provided as:

            * An ePOComputer object
            * A computer name

        This parameter can be passed in from the pipeline.

    .PARAMETER ForceFullPolicyUpdate
        Updates the agent with all polices and properties

    .PARAMETER FullProps
        Full properties will be sent by Agent.

    .PARAMETER SuperAgent
        Allows you to use a SuperAgent to broadcast wakeup calls to other agents.

    .PARAMETER AbortAfter
        Specifies total number of minutes it should wait for an agent to respond before it considers the attempt a failure.

    .PARAMETER RetryIntervalSeconds
        Specifies how long it should wait between attempts if the previous attempt to wake up an agent failed.

    .PARAMETER NumberOfAttempts
        Specifies how many times the ePO server should attempt to wake up the agent before it deems it a failure.

    .PARAMETER RandomMinutes
        Specifies number of minutes to randomise the wakeup calls
#>

function Invoke-ePOWakeUpAgent {
    [CmdletBinding()]
    [Alias('Invoke-ePOwerShellWakeUpAgent')]
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Alias('ComputerName')]
        $Computer,

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

    begin {}

    process {
        try {
            foreach ($Comp in $Computer) {
                if ($Comp -is [ePOComputer]) {
                    Write-Verbose "Computer was pipelined with an ePOComputer object"
                    $ePOComputer = $Comp
                } else {
                    Write-Verbose "Confirming computer is in ePO: $Comp"

                    if (-not ($ePOComputer = Get-ePOComputer -Computer $Comp)) {
                        Write-Error ("Failed to find computer system '{0}' in ePO" -f $Comp) -ErrorAction Stop
                        continue
                    }
                }

                Write-Verbose ('Found computer system in ePO: {0}' -f ($ePOComputer | Out-String))

                if (-not ($ePOComputer.ManagedState)) {
                    Write-Error ('Computer System is not in a managed state: {0}' -f $Comp) -ErrorAction Stop
                    continue
                }

                Write-Verbose ('Computer System is in a managed state: {0}' -f $Comp)

                $Request = @{
                    Name  = 'system.wakeupAgent'
                    Query = @{
                        names                 = $ePOComputer.ComputerName
                        fullProps             = $FullProps
                        forceFullPolicyUpdate = $ForceFullPolicyUpdate
                        abortAfterMinutes     = $AbortAfter
                        retryIntervalSeconds  = $RetryIntervalSeconds
                        attempts              = $NumberOfAttempts
                        randomMinutes         = $RandomMinutes
                        superAgent            = $SuperAgent
                    }
                }

                Write-Verbose "Request: $($Request | ConvertTo-Json)"
                $Response = Invoke-ePORequest @Request

                $Results = @{}
                foreach ($Item in (($Response | ConvertTo-Json).Split('\n').Replace('"', ''))) {
                    if ($Item) {
                        $ItemName = ($Item.Split(':')[0].Trim())
                        $ItemResults = ([Boolean]($Item.Split(':')[1].Trim() -as [Int]))
                        $Results.Add($ItemName, $ItemResults)
                    }
                }

                if ($Results.Completed) {
                    Write-Verbose ('Successfully woke up {0}' -f $ePOComputer.ComputerName)
                } elseif ($Results.Failed) {
                    Throw ('Failed to wake up {0}' -f $ePOComputer.ComputerName)
                } elseif ($Results.Expired) {
                    Throw ('Failed to wake up {0}. Session expired.' -f $ePOComputer.ComputerName)
                } else {
                    Throw ('Failed to wake up {0}. Unknown error' -f $ePOComputer.ComputerName)
                }
            }
        } catch {
            Write-Error $_
        }
    }

    end {}
}

Export-ModuleMember -Function 'Invoke-ePOWakeUpAgent' -Alias 'Invoke-ePOwerShellWakeUpAgent'