<#
    .SYNOPSIS
        Applies tags to computers managed in ePO

    .DESCRIPTION
        Using the supplied ComputerName(s) and TagName(s), we can apply the tag to the computers
        specified. Tags or Computers can be passed in through the pipeline, but not both at the same time.

    .EXAMPLE
        Set a single tag on a single computer
        ```powershell
        $Tag = Get-ePOTag -Tag 'Tag1'
        $Computer = Get-ePOComputer -Computer 'Computer1'
        Set-ePOwerShellTag -Computer $Computer -Tag $Tag
        ```

    .EXAMPLE
        Set one tag on two computers
        ```powershell
        Set-ePOwerShellTag @(Computer1, Computer2) Tag1
        ```

    .EXAMPLE
        Set two tags to a single computer:
        ```powershell
        Set-ePOwerShellTag Computer1 @(Tag1, Tag2)
        ```
#>

function Set-ePOTag {
    [CmdletBinding(SupportsShouldProcess = $True)]
    [Alias('Set-ePOwerShellTag')]
    param (
        <#
            .PARAMETER Computer
                Specifies the name of the computer managed by ePO to have a tag applied to it. This can be provided by:

                    * An ePOComputer object
                    * A computer name

                This parameter can be provided through the pipeline
        #>
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Alias('ComputerName')]
        $Computer,

        <#
            .PARAMETER Tag
                Specifies the name of the tag to be applied. This can be provided by:

                    * An ePOTag object
                    * A tag name

                This parameter can be provided through the pipeline
        #>
        [Parameter(Mandatory = $True, Position = 1, ValueFromPipeline = $True)]
        [Alias('TagName')]
        $Tag
    )

    begin {
        try {
            $Request = @{
                Name  = 'system.applyTag'
                Query = @{
                    names   = ''
                    tagName = ''
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    process {
        try {
            foreach ($C in $Computer) {
                foreach ($T in $Tag) {
                    if ($C -is [ePOComputer]) {
                        $Request.Query.names = $C.ComputerName
                    } elseif ($C -is [ePOTag]) {
                        $Request.Query.tagName = $C.Name
                    } else {
                        $Request.Query.names = $C
                    }

                    if ($T -is [ePOTag]) {
                        $Request.Query.tagName = $T.Name
                    } elseif ($T -is [ePOComputer]) {
                        $Request.Query.names = $T.ComputerName
                    } else {
                        $Request.Query.tagName = $T
                    }

                    Write-Verbose ('Computer Name: {0}' -f $Request.Query.names)
                    Write-Verbose ('Tag Name: {0}' -f $Request.Query.tagName)

                    if ($PSCmdlet.ShouldProcess("Set ePO tag $($Request.Query.tagName) from $($Request.Query.names)")) {
                        $Result = Invoke-ePORequest @Request

                        if ($Result -eq 0) {
                            Write-Verbose ('Tag [{0}] is already cleared from computer {1}' -f $T, $C)
                        } elseif ($Result -eq 1) {
                            Write-Verbose ('Successfully cleared tag [{0}] to computer {1}' -f $T, $C)
                        } else {
                            Write-Error ('Unknown response while clearing tag [{0}] from {1}: {2}' -f $T, $C, $Result) -ErrorAction Stop
                        }
                    }
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }
}