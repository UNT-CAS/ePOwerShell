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
        URL = 'https://raw.githubusercontent.com/marranaga/ePOwerShell/master/Examples/CoreHelpSpecific_Jsonalksdfjaflk.html'
    }
    Output      = @{
        Throws = $True
    }
}