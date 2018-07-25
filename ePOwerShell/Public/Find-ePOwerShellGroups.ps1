function Find-ePOwerShellGroups {
    [CmdletBinding()]
    [Alias('Find-ePOGroups')]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(ParameterSetName = 'GroupName', Position = 1)]
        [String]
        $GroupName,

        [Parameter(ParameterSetName = 'GroupName')]
        [Switch]
        $Exact
    )

    begin {
        $Request = @{
            Name    = 'system.findGroups'
            Query   = @{
                searchText  = ''
            }
        }
    }

    process {
        $Groups = Invoke-ePOwerShellRequest @Request
        [System.Collections.ArrayList] $Found = @()

        foreach ($Group in $Groups) {
            switch ($PSCmdlet.ParameterSetName) {
                "GroupName" {
                    if ($Exact) {
                        if ($Group.groupPath -match "$GroupName`$") {
                            $Found += $Group
                        }
                    } elseif ($Group.groupPath -match $GroupName) {
                        $Found += $Group
                    }
                }
                default {
                    $Found += $Group
                }
            }
        }
    }

    end {
        return $Found
    }
}