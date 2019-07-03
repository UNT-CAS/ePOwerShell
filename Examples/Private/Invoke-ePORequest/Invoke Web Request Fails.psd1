@{
    ePOwerShell = @{
        Port   = '1234'
        Server = 'https://Test-ePO-Server.com'
    }
    Username    = 'domain\username'
    Password    = 'SomePassword'
    BreakIWR    = $True
    Parameters  = @{
        Name = 'core.help'
    }
    Output      = @{
        Throws = $True
    }
}