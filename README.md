This *PowerShell Class* allows you to easily connect to and work with your McAfee ePO Server in PowerShell 5.0+.

If you've got a script that's using this, feel free to use a `settings.json` file to store your ePO settings. You can use the [settings_SAMPLE.json](settings_SAMPLE.json) as a guide.

# Quick Start

```powershell
. .\ePOwerShell.ps1
$ePO = [ePO]::new()
```

Now you can do something, like search for your current computer in ePO:

```powershell
$ePO.SystemFind($env:ComputerName)
```

See the wiki for more details.