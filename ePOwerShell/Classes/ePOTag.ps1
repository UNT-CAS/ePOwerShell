Class ePOTag {
    [System.String] $Name
    [System.Int32]  $ID
    [System.String] $Description

    ePOTag([String] $Name, [Int32] $ID, [String] $Description) {
        $this.Name = $Name
        $this.ID = $ID
        $this.Description = $Description
    }
}