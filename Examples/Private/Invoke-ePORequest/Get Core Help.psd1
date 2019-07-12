@{
    ePOwerShell = @{
        Port   = '1234'
        Server = 'https://Test-ePO-Server.com'
    }
    Username    = 'domain\username'
    Password    = 'SomePassword'
    Parameters  = @{
        Name = 'core.help'
    }
    Output      = @{
        Type = 'System.Object[]'
    }
}