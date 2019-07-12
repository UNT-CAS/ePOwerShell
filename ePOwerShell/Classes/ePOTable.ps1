Class ePOTable {
    [System.String]     $Name
    [System.String]     $Target
    [System.String]     $Type
    [System.String]     $DatabaseType
    [System.String]     $Description
    [System.String[]]   $RelatedTables
    [ePOColumn[]]       $Columns
}

Class ePOColumn {
    [System.String]     $Name
    [System.String]     $Type
    [System.Boolean]    $Select
    [System.Boolean]    $Condition
    [System.Boolean]    $GroupBy
    [System.Boolean]    $Order
    [System.Boolean]    $Number
}