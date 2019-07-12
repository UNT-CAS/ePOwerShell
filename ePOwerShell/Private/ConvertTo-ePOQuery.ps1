function ConvertTo-ePOQuery {
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $True)]
        [PSCustomObject]
        $ePOQuery
    )

    $ePOQueryObject = [ePOQuery]::new()

    $ePOQueryObject.ID = $ePOQuery.id
    $ePOQueryObject.Name = $ePOQuery.name
    $ePOQueryObject.Description = $ePOQuery.description
    $ePOQueryObject.ConditionSexp = $ePOQuery.conditionSexp
    $ePOQueryObject.GroupName = $ePOQuery.GroupName
    $ePOQueryObject.UserName = $ePOQuery.userName
    $ePOQueryObject.DatabaseType = $ePOQuery.databaseType
    $ePOQueryObject.CreatedOn = if ($ePOQuery.createdOn) { $ePOQuery.createdOn }
    $ePOQueryObject.CreatedBy = $ePOQuery.createdBy
    $ePOQueryObject.ModifiedOn= if ($ePOQuery.modifiedOn) { $ePOQuery.modifiedOn }
    $ePOQueryObject.ModifiedBy = $ePOQuery.modifiedBy

    Write-Output $ePOQueryObject
}