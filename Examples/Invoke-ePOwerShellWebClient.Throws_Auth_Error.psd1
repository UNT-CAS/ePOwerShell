@{
    ePOwerShell = @{
        Port        = '1234'
        Server      = 'Test-ePO-Server.com'
        Credentials = @{
            Username = 'domain\username'
            Password = 'SomePassword'
        }
    }
    Parameters  = @{
        URL = 'https://github.com/UNT-CAS/ePOwerShell/settings/hooks'
    }
    Output      = @{
        Throws = $True
    }
}