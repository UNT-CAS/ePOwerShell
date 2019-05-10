Class ePOTable {
    [System.String] $Name
    [System.String] $Target
    [System.String] $Type
    [System.String] $DatabaseType
    [System.String] $Description
    [System.String[]] $RelatedTables
    [ePOColumns]    $Columns
}

Class ePOColumns {
    [System.String] $Name
    [System.String] $Type
    [System.Boolean] $Select
    [System.Boolean] $Condition
    [System.Boolean] $GroupBy
    [System.Boolean] $Order
    [System.Boolean] $Number
}