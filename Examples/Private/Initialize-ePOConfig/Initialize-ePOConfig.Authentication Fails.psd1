@{
    Port         = '1234'
    Server       = 'Test-ePO-Server.com'
    Username     = 'domain\username'
    Password     = 'SomePassword'
    CoreHelpFail = $True
    Output       = @{
        Throws = $True
    }
}