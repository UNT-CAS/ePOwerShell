<#
.SYNOPSIS

Write the WHERE portion of the ePO custom query.

.DESCRIPTION

Write the WHERE portion of the ePO custom query returning the string that's ready to be sent to ePO.

.PARAMETER WherePart

A hashtable of the structure of the WHERE clause. See examples.

.PARAMETER Parent

This is really just called when re-calling this function from within itself.
You probably shouldn't pass this parameter manually.

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
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]
        $WherePart,

        [Parameter()]
        [string]
        $Parent
    )

    foreach ($part in $WherePart.GetEnumerator()) {
        if ($part.Value -is [hashtable]) {
            if (@('and', 'or') -contains $part.Name) {
                $return += ' ({0} {1})' -f $part.Name, (Write-ePOWhere $part.Value -Parent $part.Name)
            } else {
                $return += ' {1}' -f $part.Name, (Write-ePOWhere $part.Value -Parent $part.Name)
            }
        } else {
            $value = $part.Value
            $return += ' ({0} {1} {2})' -f $Parent, $part.Name, $value
        }
    }

    while ($return.Contains('  ')) {
        $return = $return.Replace('  ', ' ')
    }
    $return = $return.Trim()

    if ((-not $Parent) -and ($return.StartsWith('(eq') -or $return.StartsWith('(ne'))) {
        $return = '(where {0})' -f $return
    }

    return $return
}
