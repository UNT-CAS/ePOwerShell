[![Build status](https://ci.appveyor.com/api/projects/status/t3kx0sy41ouw7cry?svg=true)](https://ci.appveyor.com/project/UNT-CAS/ePOwerShell)
[![codecov](https://codecov.io/gh/UNT-CAS/ePOwerShell/branch/master/graph/badge.svg)](https://codecov.io/gh/UNT-CAS/ePOwerShell)
[![version](https://img.shields.io/powershellgallery/v/ePOwerShell.svg)](https://www.powershellgallery.com/packages/ePOwerShell)
[![downloads](https://img.shields.io/powershellgallery/dt/ePOwerShell.svg?label=downloads)](https://www.powershellgallery.com/stats/packages/ePOwerShell?groupby=Version)

# Quick Start

```powershell
Import-Module ePOwerShell

$ePOwerShellServer = @{
    Server = 'your-epo-server.com'
    Port = 1234
    Credentials = (Get-Credential)
}

Set-ePOwerShellServer @ePOwershellServer
```

From here, you're able to use the rest of the functions:

```powershell
$Computer = Find-ePOwerShellComputerSystem $env:ComputerName
```

The rest of the functions are detailed further in [the wiki](../../wiki).
