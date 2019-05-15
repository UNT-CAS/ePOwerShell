@{
    ePOwerShell = @{
        Server   = "my-epo-server.com"
        Port     = "1234"
        Username = "Domain\Username"
        Password = "ThisIsAPassword"
    }
    UpdatingCredentials = $True
    Credentials = @{
        Username = "Domain\Username2"
        Password = "ThisIsAPasswordToo"
    }
    Output      = @{
        Type = 'System.Void'
    }
}