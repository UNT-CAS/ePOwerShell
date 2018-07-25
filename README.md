[![Build status](https://ci.appveyor.com/api/projects/status/t3kx0sy41ouw7cry?svg=true)](https://ci.appveyor.com/project/VertigoRay/ePOwerShell)
[![codecov](https://codecov.io/gh/UNT-CAS/ePOwerShell/branch/master/graph/badge.svg)](https://codecov.io/gh/UNT-CAS/ePOwerShell)
[![version](https://img.shields.io/powershellgallery/v/ePOwerShell.svg)](https://www.powershellgallery.com/packages/ePOwerShell)
[![downloads](https://img.shields.io/powershellgallery/dt/ePOwerShell.svg?label=downloads)](https://www.powershellgallery.com/packages/ePOwerShell)

# Quick Start

```powershell
Import-Module ePOwerShell

$ePOwerShellServer = @{
    Server = 'your-epo-server.com'
    Port = 1234
    Output = 'json'
    Credentials = (Get-Credential)
}

Set-ePOwerShellServer @ePOwershellServer
```

From here, you're free to use the rest of the functions:

```powershell
$Computer = Find-ePOwerShellComputerSystem 'My-Computer'
```