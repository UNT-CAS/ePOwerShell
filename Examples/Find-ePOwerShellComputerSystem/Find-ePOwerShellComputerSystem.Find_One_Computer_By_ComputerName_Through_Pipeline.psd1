@{
    Parameters = @{
        ComputerName = "Computer1"
    }
    Pipeline = $True
    Output     = @{
        Type  = 'System.Object[]'
        Count = 1
    }
}