@{
    Parameters = @{
        ComputerName = @("Computer1", "Computer2")
    }
    Pipeline   = $True
    Output     = @{
        Type  = 'System.Object[]'
        Count = 2
    }
}