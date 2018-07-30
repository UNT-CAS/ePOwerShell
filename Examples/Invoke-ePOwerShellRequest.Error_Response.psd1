@{
    File        = 'ErrorMessage.html'
    ePOwerShell = @{
        Port     = '1234'
        Server   = 'Test-ePO-Server.com'
        Username = 'domain\username'
        Password = 'SomePassword'
    }
    Parameters  = @{
        Name    = 'core.help'
    }
    Output      = @{
        Throws  = $True
    }
}