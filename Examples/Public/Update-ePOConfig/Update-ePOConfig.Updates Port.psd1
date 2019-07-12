@{
    ePOwerShell = @{
        Server               = "my-epo-server.com"
        Port                 = "1234"
        Username             = "Domain\Username"
        Password             = "ThisIsAPassword"
        AllowSelfSignedCerts = $False
    }
    Parameters  = @{
        Port = 4321
    }
    Output      = @{
        Type = 'System.Void'
    }
}