@{
    File        = 'CoreHelp_Json.html'
    ePOwerShell = @{
        Port     = '1234'
        Server   = 'Test-ePO-Server.com'
        Username = 'domain\username'
        Password = 'SomePassword'
    }
    Parameters  = @{
        Name = 'core.help'
        PassThru = $True
    }
    Output      = @{
        Type = 'System.String'
    }
}