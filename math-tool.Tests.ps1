BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'math-tool.ps1'
    . $script:ScriptPath

    function Invoke-MathToolCli {
        param(
            [Parameter(Mandatory)]
            [string] $NValue,

            [string] $OperationValue
        )

        $arguments = @('-NoLogo', '-NoProfile', '-File', $script:ScriptPath, '-N', $NValue)
        if ($PSBoundParameters.ContainsKey('OperationValue')) {
            $arguments += @('-Operation', $OperationValue)
        }

        $standardOutputPath = New-TemporaryFile
        $standardErrorPath = New-TemporaryFile
        try {
            $process = Start-Process -FilePath (Get-Process -Id $PID).Path `
                -ArgumentList $arguments `
                -RedirectStandardOutput $standardOutputPath `
                -RedirectStandardError $standardErrorPath `
                -Wait -PassThru

            [pscustomobject]@{
                ExitCode = $process.ExitCode
                StdOut   = (Get-Content -LiteralPath $standardOutputPath -Raw)
                StdErr   = (Get-Content -LiteralPath $standardErrorPath -Raw)
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
        $output[0] | Should -BeOfType [bigint]
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

    It 'exposes Get-Factorial' {
        Get-Command -Name Get-Factorial -CommandType Function | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-Factorial' {
    It 'returns 1 for N=0' {
        Get-Factorial -N 0 | Should -Be 1
    }

    It 'returns 1 for N=1' {
        Get-Factorial -N 1 | Should -Be 1
    }

    It 'returns 120 for N=5' {
        Get-Factorial -N 5 | Should -Be 120
    }

    It 'emits only the numeric result with no incidental output' {
        $output = @(Get-Factorial -N 5)
        $output.Count | Should -Be 1
        $output[0] | Should -BeOfType [bigint]
    }

    It 'rejects negative input instead of computing a value' {
        { Get-Factorial -N -1 } | Should -Throw
    }
}

Describe 'math-tool.ps1 direct execution' {
    It 'prints Fibonacci(<n>) = <expected> and exits successfully' -ForEach @(
        @{ N = 0; Expected = '0' }
        @{ N = 1; Expected = '1' }
        @{ N = 10; Expected = '55' }
    ) {
        $result = Invoke-MathToolCli -NValue "$N"
        $result.ExitCode | Should -Be 0
        $result.StdOut.Trim() | Should -BeExactly "Fibonacci($N) = $Expected"
    }

    It 'writes exactly one non-empty result line to stdout' {
        $result = Invoke-MathToolCli -NValue '10'
        $lines = @($result.StdOut -split '\r?\n' | Where-Object { $_ -ne '' })
        $lines.Count | Should -Be 1
        $lines[0] | Should -BeExactly 'Fibonacci(10) = 55'
    }

    It 'rejects negative input without producing a result line' {
        $result = Invoke-MathToolCli -NValue '-1'
        $result.ExitCode | Should -Not -Be 0
        $result.StdOut | Should -BeNullOrEmpty
        $result.StdErr | Should -Not -BeNullOrEmpty
    }
}

Describe 'math-tool.ps1 operation dispatch' {
    It 'prints Factorial(<n>) = <expected> and exits successfully' -ForEach @(
        @{ N = 0; Expected = '1' }
        @{ N = 1; Expected = '1' }
        @{ N = 5; Expected = '120' }
    ) {
        $result = Invoke-MathToolCli -NValue "$N" -OperationValue 'factorial'
        $result.ExitCode | Should -Be 0
        $result.StdOut.Trim() | Should -BeExactly "Factorial($N) = $Expected"
    }

    It 'writes exactly one non-empty result line for factorial' {
        $result = Invoke-MathToolCli -NValue '5' -OperationValue 'factorial'
        $lines = @($result.StdOut -split '\r?\n' | Where-Object { $_ -ne '' })
        $lines.Count | Should -Be 1
        $lines[0] | Should -BeExactly 'Factorial(5) = 120'
    }

    It 'prints Fibonacci(<n>) = <expected> for explicit fibonacci dispatch' -ForEach @(
        @{ N = 0; Expected = '0' }
        @{ N = 1; Expected = '1' }
        @{ N = 10; Expected = '55' }
    ) {
        $result = Invoke-MathToolCli -NValue "$N" -OperationValue 'fibonacci'
        $result.ExitCode | Should -Be 0
        $result.StdOut.Trim() | Should -BeExactly "Fibonacci($N) = $Expected"
    }

    It 'matches the default behavior when fibonacci is requested explicitly' {
        $explicit = Invoke-MathToolCli -NValue '10' -OperationValue 'fibonacci'
        $default = Invoke-MathToolCli -NValue '10'
        $explicit.ExitCode | Should -Be $default.ExitCode
        $explicit.StdOut | Should -BeExactly $default.StdOut
    }

    It 'rejects an unsupported operation without producing a result line' {
        $result = Invoke-MathToolCli -NValue '5' -OperationValue 'cube'
        $result.ExitCode | Should -Not -Be 0
        $result.StdOut | Should -BeNullOrEmpty
        $result.StdErr | Should -Not -BeNullOrEmpty
    }

    It 'rejects negative input for factorial without producing a result line' {
        $result = Invoke-MathToolCli -NValue '-1' -OperationValue 'factorial'
        $result.ExitCode | Should -Not -Be 0
        $result.StdOut | Should -BeNullOrEmpty
        $result.StdErr | Should -Not -BeNullOrEmpty
    }
}
