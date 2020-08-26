[![Build status](https://ci.appveyor.com/api/projects/status/t3kx0sy41ouw7cry?svg=true)](https://ci.appveyor.com/project/UNTCAS/ePOwerShell)
[![version](https://img.shields.io/powershellgallery/v/ePOwerShell.svg)](https://www.powershellgallery.com/packages/ePOwerShell)
[![downloads](https://img.shields.io/powershellgallery/dt/ePOwerShell.svg?label=downloads)](https://www.powershellgallery.com/stats/packages/ePOwerShell?groupby=Version)

# Quick Start

```powershell
Import-Module ePOwerShell

$ePOwerShellServer = @{
    Server = 'https://your-epo-server.com'
    Port = 1234
    Credentials = (Get-Credential)
    AllowSelfSignedCerts = $True
}

Set-ePOConfig @ePOwershellServer
```

From here, you're able to use the rest of the functions:

```powershell
$Computer = Get-ePOComputer $env:ComputerName
```

The rest of the functions are detailed further in [the wiki](../../wiki).

# Tips and Tricks

## Save ePO Config

If you don't want to do `Set-ePOConfig` every time you load powershell, try [`Save-ePOConfig`](https://github.com/UNT-CAS/ePOwerShell/wiki/Save-ePOConfig).
