# Repository hygiene: the repository must stay synthetic and free of real organisation names.
# Terms that must never appear are stored base64-encoded so that this file does not contain them itself.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $decode = { param([string]$s) [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($s)) }

    # Each entry: encoded regular expression, and whether the match is case-sensitive.
    $script:Forbidden = @(
        @{ Pattern = (& $decode 'SW50ZXJuYXRpb25hbCBDYXJnbyBMb2dpc3RpY3M='); CaseSensitive = $false }
        @{ Pattern = (& $decode 'TWVudGZpZWxk'); CaseSensitive = $false }
        @{ Pattern = (& $decode 'QXNjb20='); CaseSensitive = $false }
        @{ Pattern = (& $decode 'VHJhbnMgRGF0YSBNYW5hZ2VtZW50'); CaseSensitive = $false }
        @{ Pattern = (& $decode 'ZnJhY3Rpb25hbCBDVE8='); CaseSensitive = $false }
        @{ Pattern = (& $decode 'Q2xhdWRl'); CaseSensitive = $false }
        @{ Pattern = (& $decode 'QW50aHJvcGlj'); CaseSensitive = $false }
        @{ Pattern = (& $decode 'XGJJQ0xcYg=='); CaseSensitive = $true }
        @{ Pattern = (& $decode 'XGJURE1cYg=='); CaseSensitive = $true }
    )

    $script:TextFiles = Get-ChildItem -LiteralPath $script:RepoRoot -Recurse -File -Force |
        Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' -and $_.Extension -notin '.png', '.jpg', '.gif' }
}

Describe 'Repository hygiene' {
    It 'finds files to check' {
        $script:TextFiles.Count | Should -BeGreaterThan 10
    }

    It 'contains none of the forbidden real-world names' {
        $hits = foreach ($file in $script:TextFiles) {
            $text = Get-Content -LiteralPath $file.FullName -Raw
            foreach ($f in $script:Forbidden) {
                $found = if ($f.CaseSensitive) { $text -cmatch $f.Pattern } else { $text -imatch $f.Pattern }
                if ($found) { $file.Name }
            }
        }
        @($hits) | Should -BeNullOrEmpty
    }

    It 'uses no em-dashes or en-dashes' {
        $dashes = [regex]('[' + [char]0x2013 + [char]0x2014 + ']')
        $hits = $script:TextFiles | Where-Object { $dashes.IsMatch((Get-Content -LiteralPath $_.FullName -Raw)) } | ForEach-Object Name
        @($hits) | Should -BeNullOrEmpty
    }

    It 'uses only reserved example domains for email-style addresses in synthetic data' {
        $files = $script:TextFiles | Where-Object { $_.FullName -match '[\\/](src|tests)[\\/]' }
        $bad = foreach ($file in $files) {
            [regex]::Matches((Get-Content -LiteralPath $file.FullName -Raw), '[\w.+-]+@([\w-]+(?:\.[\w-]+)+)') |
                ForEach-Object { $_.Groups[1].Value } |
                Where-Object { $_ -notmatch '\.example$' -and $_ -notmatch '^(microsoft|onmicrosoft)\.com$' }
        }
        @($bad | Select-Object -Unique) | Should -BeNullOrEmpty
    }
}
