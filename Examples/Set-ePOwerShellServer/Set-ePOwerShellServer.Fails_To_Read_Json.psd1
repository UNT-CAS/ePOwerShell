@{
    ePOwerShellFilepath   = '{0}\ePOwerShell.json'
    ePOwerShellFilepath_f = @('$env:Temp')
    BreakJson = $True
    ePOwerShell           = @{
        Server   = "my-epo-server.com"
        Port     = "1234"
        Username = "Domain\Username"
        Password = "ThisIsAPassword"
    }
    Output = @{
        Throws = $True
    }
}