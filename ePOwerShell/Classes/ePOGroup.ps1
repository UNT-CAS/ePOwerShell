Class ePOGroup {
    [System.String] $Name
    [System.Int32]  $ID

    ePOGroup([String]$Name, [Int32] $ID) {
        $This.Name = $Name
        $This.ID   = $ID
    }
}