@{
    Parameters = @{
        GroupName = @(
            'Group1',
            'Group2'
        )
        PassThru  = $True
    }
    Output     = @{
        Type  = 'System.Object[]'
        Count = 2
    }
}