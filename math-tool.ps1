[CmdletBinding()]
param(
    [ValidateRange(0, [int]::MaxValue)]
    [int] $N = 0
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

if ($MyInvocation.InvocationName -ne '.') {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    Write-Output ('Fibonacci({0}) = {1}' -f $N, (Get-Fibonacci -N $N))
}
