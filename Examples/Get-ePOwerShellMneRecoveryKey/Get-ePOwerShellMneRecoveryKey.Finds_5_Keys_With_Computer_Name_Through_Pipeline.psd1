@{
    Parameters = @{
        ComputerName = @(
            'Computer1',
            'Computer2',
            'Computer3',
            'Computer4',
            'Computer5'
        )
    }
    Pipeline = $True
    Output     = @{
        Type  = 'System.Object[]'
        Count = 5
    }
}