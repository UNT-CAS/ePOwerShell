@{
    Parameters = @{
        Tag = @(
            'Tag1',
            'Tag2',
            'Tag3'
        )
    }
    Pipeline   = $True
    Output     = @{
        Type  = 'System.Object[]'
        Count = 3
    }
}