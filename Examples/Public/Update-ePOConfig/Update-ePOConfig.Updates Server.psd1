@{
    ePOwerShell = @{
        Server   = "my-epo-server.com"
        Port     = "1234"
        Username = "Domain\Username"
        Password = "ThisIsAPassword"
        AllowSelfSignedCerts = $False
    }
    Parameters  = @{
        Server = "My-ePO-Server-2.domain.com"
    }
    Output      = @{
        Type = 'System.Void'
    }
}