function ConvertTo-ePOComputer {
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $True)]
        [PSCustomObject]
        $ePOComputer
    )

    $ePOComputerObject = [ePOComputer]::new()

    $ePOComputerObject.ParentID = $ePOComputer.'EPOComputerProperties.ParentID'
    $ePOComputerObject.ComputerName = $ePOComputer.'EPOComputerProperties.ComputerName'
    $ePOComputerObject.Description = $ePOComputer.'EPOComputerProperties.Description'
    $ePOComputerObject.SystemDescription = $ePOComputer.'EPOComputerProperties.SystemDescription'
    $ePOComputerObject.TimeZone = $ePOComputer.'EPOComputerProperties.TimeZone'
    $ePOComputerObject.DefaultLangID = $ePOComputer.'EPOComputerProperties.DefaultLangID'
    $ePOComputerObject.UserName = $ePOComputer.'EPOComputerProperties.UserName'
    $ePOComputerObject.DomainName = $ePOComputer.'EPOComputerProperties.DomainName'
    $ePOComputerObject.IPHostName = $ePOComputer.'EPOComputerProperties.IPHostName'
    $ePOComputerObject.IPV6 = $ePOComputer.'EPOComputerProperties.IPV6'
    $ePOComputerObject.IPAddress = $ePOComputer.'EPOComputerProperties.IPAddress'
    $ePOComputerObject.IPSubnet = $ePOComputer.'EPOComputerProperties.IPSubnet'
    $ePOComputerObject.IPSubnetMask = $ePOComputer.'EPOComputerProperties.IPSubnetMask'
    $ePOComputerObject.IPV4x = $ePOComputer.'EPOComputerProperties.IPV4x'
    $ePOComputerObject.IPXAddress = $ePOComputer.'EPOComputerProperties.IPXAddress'
    $ePOComputerObject.SubnetAddress = $ePOComputer.'EPOComputerProperties.SubnetAddress'
    $ePOComputerObject.SubnetMask = $ePOComputer.'EPOComputerProperties.SubnetMask'
    $ePOComputerObject.NetAddress = $ePOComputer.'EPOComputerProperties.NetAddress'
    $ePOComputerObject.OSType = $ePOComputer.'EPOComputerProperties.OSType'
    $ePOComputerObject.OSVersion = $ePOComputer.'EPOComputerProperties.OSVersion'
    $ePOComputerObject.OSServicePackVer = $ePOComputer.'EPOComputerProperties.OSServicePackVer'
    $ePOComputerObject.OSBuildNum = $ePOComputer.'EPOComputerProperties.OSBuildNum'
    $ePOComputerObject.OSPlatform = $ePOComputer.'EPOComputerProperties.OSPlatform'
    $ePOComputerObject.OSOEMID = $ePOComputer.'EPOComputerProperties.OSOEMID'
    $ePOComputerObject.CPUType = $ePOComputer.'EPOComputerProperties.CPUType'
    $ePOComputerObject.CPUSpeed = $ePOComputer.'EPOComputerProperties.CPUSpeed'
    $ePOComputerObject.NumOfCPU = $ePOComputer.'EPOComputerProperties.NumOfCPU'
    $ePOComputerObject.CPUSerialNum = $ePOComputer.'EPOComputerProperties.CPUSerialNum'
    $ePOComputerObject.TotalPhysicalMemory = ([Math]::Round($ePOComputer.'EPOComputerProperties.TotalPhysicalMemory'/1GB))
    $ePOComputerObject.FreeMemory = ([Math]::Round($ePOComputer.'EPOComputerProperties.FreeMemory'/1GB))
    $ePOComputerObject.FreeDiskSpace = ([Math]::Round($ePOComputer.'EPOComputerProperties.FreeDiskSpace'/1GB))
    $ePOComputerObject.TotalDiskSpace = ([Math]::Round($ePOComputer.'EPOComputerProperties.TotalDiskSpace'/1GB))
    $ePOComputerObject.IsPortable = $ePOComputer.'EPOComputerProperties.IsPortable'
    $ePOComputerObject.Vdi = $ePOComputer.'EPOComputerProperties.Vdi'
    $ePOComputerObject.OSBitMode = $ePOComputer.'EPOComputerProperties.OSBitMode'
    $ePOComputerObject.LastAgentHandler = $ePOComputer.'EPOComputerProperties.LastAgentHandler'
    $ePOComputerObject.UserProperty1 = $ePOComputer.'EPOComputerProperties.UserProperty1'
    $ePOComputerObject.UserProperty2 = $ePOComputer.'EPOComputerProperties.UserProperty2'
    $ePOComputerObject.UserProperty3 = $ePOComputer.'EPOComputerProperties.UserProperty3'
    $ePOComputerObject.UserProperty4 = $ePOComputer.'EPOComputerProperties.UserProperty4'
    $ePOComputerObject.UserProperty5 = $ePOComputer.'EPOComputerProperties.UserProperty5'
    $ePOComputerObject.UserProperty6 = $ePOComputer.'EPOComputerProperties.UserProperty6'
    $ePOComputerObject.UserProperty7 = $ePOComputer.'EPOComputerProperties.UserProperty7'
    $ePOComputerObject.UserProperty8 = $ePOComputer.'EPOComputerProperties.UserProperty8'
    $ePOComputerObject.SysvolFreeSpace = $ePOComputer.'EPOComputerProperties.SysvolFreeSpace'
    $ePOComputerObject.SysvolTotalSpace = $ePOComputer.'EPOComputerProperties.SysvolTotalSpace'
    $ePOComputerObject.Tags = ($ePOComputer.'EPOLeafNode.Tags').Split(',').Trim()
    $ePOComputerObject.ExcludedTags = ($ePOComputer.'EPOLeafNode.ExcludedTags').Split(',').Trim()
    $ePOComputerObject.LastUpdate = $ePOComputer.'EPOLeafNode.LastUpdate'
    $ePOComputerObject.ManagedState = $ePOComputer.'EPOLeafNode.ManagedState'
    $ePOComputerObject.AgentGUID = $ePOComputer.'EPOLeafNode.AgentGUID'
    $ePOComputerObject.AgentVersion = $ePOComputer.'EPOLeafNode.AgentVersion'
    $ePOComputerObject.AutoID = $ePOComputer.'EPOBranchNode.AutoID'

    Write-Output $ePOComputerObject
}