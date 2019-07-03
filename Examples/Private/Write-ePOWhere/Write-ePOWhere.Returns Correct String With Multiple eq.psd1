@{
    Parameters = @{
        Where = @{
            and = @{
                eq = @{
                    EPOLeafNodeId = 1234
                    ComputerName  = 'CAS-12345'
                }
            }
        }
    }
    Response = '(and (eq ComputerName "CAS-12345") (eq EPOLeafNodeId "1234"))'
}