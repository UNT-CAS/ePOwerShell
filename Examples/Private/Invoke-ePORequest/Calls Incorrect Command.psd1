@{
    ePOwerShell = @{
        Port   = '1234'
        Server = 'https://Test-ePO-Server.com'
    }
    Username    = 'domain\username'
    Password    = 'SomePassword'
    Parameters  = @{
        Name = 'Something.Random2'
    }
    Output      = @{
        Throws = $True
    }
}