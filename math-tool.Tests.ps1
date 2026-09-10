BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'math-tool.ps1'
    . $script:ScriptPath

    function Invoke-MathToolCli {
        param(
            [Parameter(Mandatory)]
            [string] $Arguments
        )

        $standardOutputPath = New-TemporaryFile
        $standardErrorPath = New-TemporaryFile
        try {
            $process = Start-Process -FilePath (Join-Path $PSHOME 'pwsh') `
                -ArgumentList @('-NoLogo', '-NoProfile', '-File', $script:ScriptPath, '-N', $Arguments) `
                -RedirectStandardOutput $standardOutputPath `
                -RedirectStandardError $standardErrorPath `
                -Wait -PassThru -NoNewWindow

            [pscustomobject]@{
                ExitCode = $process.ExitCode
                StdOut   = (Get-Content -LiteralPath $standardOutputPath -Raw)
            }
        }
        finally {
            Remove-Item -LiteralPath $standardOutputPath, $standardErrorPath -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Get-Fibonacci' {
    It 'returns 0 for N=0' {
        Get-Fibonacci -N 0 | Should -Be 0
    }

    It 'returns 1 for N=1' {
        Get-Fibonacci -N 1 | Should -Be 1
    }

    It 'returns 55 for N=10' {
        Get-Fibonacci -N 10 | Should -Be 55
    }

    It 'emits only the numeric result with no incidental output' {
        $output = @(Get-Fibonacci -N 10)
        $output.Count | Should -Be 1
        $output[0] | Should -BeOfType [long]
    }

    It 'rejects negative input instead of computing a value' {
        { Get-Fibonacci -N -1 } | Should -Throw
    }
}

Describe 'math-tool.ps1 dot-sourcing' {
    It 'exposes Get-Fibonacci without emitting CLI output' {
        $output = @(. $script:ScriptPath)
        $output.Count | Should -Be 0
        Get-Command -Name Get-Fibonacci -CommandType Function | Should -Not -BeNullOrEmpty
    }
}

Describe 'math-tool.ps1 direct execution' {
    It 'prints Fibonacci(<n>) = <expected> and exits successfully' -ForEach @(
        @{ N = 0; Expected = '0' }
        @{ N = 1; Expected = '1' }
        @{ N = 10; Expected = '55' }
    ) {
        $result = Invoke-MathToolCli -Arguments "$N"
        $result.ExitCode | Should -Be 0
        $result.StdOut.Trim() | Should -BeExactly "Fibonacci($N) = $Expected"
    }

    It 'writes exactly one non-empty result line to stdout' {
        $result = Invoke-MathToolCli -Arguments '10'
        $lines = @($result.StdOut -split '\r?\n' | Where-Object { $_ -ne '' })
        $lines.Count | Should -Be 1
        $lines[0] | Should -BeExactly 'Fibonacci(10) = 55'
    }

    It 'rejects negative input without producing a result line' {
        $result = Invoke-MathToolCli -Arguments '-1'
        $result.ExitCode | Should -Not -Be 0
        $result.StdOut | Should -BeNullOrEmpty
    }
}
