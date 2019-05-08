@{
    IncludeDefaultRules = $True
    Rules               = @{
        PSUseConsistentWhitespace  = @{
            CheckInnerBrace = $True
            CheckPipe       = $True
        }
        PSAvoidUsingCmdletAliases  = @{
            Enable = $True
        }
        PSAlignAssignmentStatement = @{
            Enable = $True
        }
        PSPlaceOpenBrace           = @{
            Enable       = $True
            OnSameLine   = $True
            NewLineAfter = $True
        }
        PSUseCorrectCasing         = @{
            Enable = $True
        }
        PSAvoidUsingWriteHost      = @{
            Enable = $True
        }
        PSUseCompatibleCmdlets     = @{
            Compatibility = @(
                'core-6.1.0-windows',
                'desktop-5.0-windows'
            )
        }
        PSUseCompatibleSyntax      = @{
            Enable         = $True
            TargetVersions = @(
                '5.0',
                '5.1',
                '6.2'
            )
        }
    }
}