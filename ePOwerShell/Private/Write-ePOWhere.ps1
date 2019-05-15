<#
    .SYNOPSIS
        Write the WHERE portion of the ePO custom query.

    .DESCRIPTION
        Write the WHERE portion of the ePO custom query returning the string that's ready to be sent to ePO.

    .EXAMPLE
        ```powershell
        $where = @{
            and = @{
                eq = @{
                    EPOLeafNodeId = 1234
                    ComputerName  = 'CAS-12345'
                }
            }
        }
        Write-ePOWhere $where
        ```

        Output:
        ```
        (and (eq ComputerName CAS-12345) (eq EPOLeafNodeId 1234))
        ```

    .EXAMPLE
        ```powershell
        $where = @{
            or = @{
                eq = @{
                    EPOLeafNodeId = 1234
                    ComputerName = 'CAS-12345'
                }
                ne = @{
                    EPOLeafNodeId = 4321
                }
            }
        }
        Write-ePOWhere $where
        ```

        Output:
        ```
        (or (eq ComputerName CAS-12345) (eq EPOLeafNodeId 1234) (ne EPOLeafNodeId 4321))
        ```

    .EXAMPLE
        ```powershell
        $where = @{
            eq = @{
                EPOLeafNodeId = 1234
            }
        }
        Write-ePOWhere $where
        ```

        Output:
        ```
        (where (eq EPOLeafNodeId 1234))
        ```
#>
function Write-ePOWhere {
    [CmdletBinding()]
    param(
        <#
            .PARAMETER WherePart
                A hashtable of the structure of the WHERE clause. See examples.
        #>
        [Parameter(Mandatory = $true)]
        [hashtable]
        $WherePart,

        <#
            .PARAMETER Parent
                This is really just called when re-calling this function from within itself.
                You probably shouldn't pass this parameter manually.
        #>
        [Parameter()]
        [string]
        $Parent
    )

    foreach ($Part in $WherePart.GetEnumerator()) {
        if ($Part.Value -is [hashtable]) {
            if (@('and', 'or') -contains $Part.Name) {
                $Return += ' ({0} {1})' -f $Part.Name, (Write-ePOWhere $Part.Value -Parent $Part.Name)
            } else {
                $Return += ' {1}' -f $Part.Name, (Write-ePOWhere $Part.Value -Parent $Part.Name)
            }
        } else {
            $Value = $Part.Value
            $Return += ' ({0} {1} "{2}")' -f $Parent, $Part.Name, $Value
        }
    }

    while ($Return.Contains('  ')) {
        $Return = $Return.Replace('  ', ' ')
    }
    $Return = $Return.Trim()

    if ((-not $Parent) -and ($Return.StartsWith('(eq') -or $Return.StartsWith('(ne'))) {
        $Return = '(where {0})' -f $Return
    }

    Write-Output $Return
}
