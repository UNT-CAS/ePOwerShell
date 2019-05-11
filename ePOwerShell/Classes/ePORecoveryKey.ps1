Class ePORecoveryKey {
    [System.String] $ComputerName
    [System.String] $DriveLetter
    [System.String] $RecoveryKey

    ePORecoveryKey([System.String] $ComputerName, [System.String] $DriveLetter, [System.String] $RecoveryKey) {
        $this.ComputerName = $ComputerName
        $this.DriveLetter = $DriveLetter
        $this.RecoveryKey = $RecoveryKey
    }
}