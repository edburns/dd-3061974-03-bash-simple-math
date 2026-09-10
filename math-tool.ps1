[CmdletBinding()]
param(
    [ValidateRange(0, [int]::MaxValue)]
    [int] $N = 0,

    [ValidateSet('fibonacci', 'factorial')]
    [string] $Operation = 'fibonacci'
)

function Get-Fibonacci {
    [CmdletBinding()]
    [OutputType([bigint])]
    param(
        [Parameter(Mandatory)]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $N
    )

    [bigint] $previous = 0
    [bigint] $current = 1
    for ($index = 0; $index -lt $N; $index++) {
        $next = $previous + $current
        $previous = $current
        $current = $next
    }

    return $previous
}

function Get-Factorial {
    [CmdletBinding()]
    [OutputType([bigint])]
    param(
        [Parameter(Mandatory)]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $N
    )

    [bigint] $product = 1
    for ($index = 2; $index -le $N; $index++) {
        $product = $product * $index
    }

    return $product
}

if ($MyInvocation.InvocationName -ne '.') {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    switch ($Operation) {
        'fibonacci' { Write-Output ('Fibonacci({0}) = {1}' -f $N, (Get-Fibonacci -N $N)) }
        'factorial' { Write-Output ('Factorial({0}) = {1}' -f $N, (Get-Factorial -N $N)) }
        default { throw "Unsupported operation '$Operation'." }
    }
}
