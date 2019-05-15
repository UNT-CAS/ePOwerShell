@{
    where = @{
        or = @{
            eq = @{
                EPOLeafNodeId = 1234
                ComputerName = 'CAS-12345'
            }
            ne = @{
                EPOLeafNodeId = 4321
            }
        }
    }
    Response = '(or (eq ComputerName "CAS-12345") (eq EPOLeafNodeId "1234") (ne EPOLeafNodeId "4321"))'
}