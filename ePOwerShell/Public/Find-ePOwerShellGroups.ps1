function Find-ePOwerShellGroups {
    [CmdletBinding()]
    [Alias('Find-ePOGroups')]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(ParameterSetName = 'GroupName')]
        [String]
        $GroupName,

        [Parameter(ParameterSetName = 'GroupName')]
        [Switch]
        $Exact,

        [Hashtable]
        $Request = @{
            Name        = 'system.findGroups'
            SearchText  = '' 
        }
    )

    begin {}

    process {
        $Groups = Invoke-ePOwerShellRequest @Request
        [System.Collections.ArrayList] $Found = @()

        foreach ($Group in $Groups) {
            switch ($PSBoundParameters.Keys) {
                'GroupName' {
                    if (
                        ($Exact) -and
                        ($Group -match "$GroupName`$")
                    ) {
                        $Found.Add($Group)
                    } elseif ($Group -match $GroupName) {
                        $Found.Add($Group)
                    }
                }
                default {
                    $Found.Add($item)
                }
            }
        }
    }

    end {
        return $Found
    }
}