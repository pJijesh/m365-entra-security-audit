function Get-AuditProp {
    <#
    .SYNOPSIS
        Reads a property from an SDK object, a dictionary or a deserialised JSON object without throwing.
    #>
    [CmdletBinding()]
    param(
        $Object,
        [Parameter(Mandatory)][string]$Name
    )

    if ($null -eq $Object) { return $null }

    if ($Object -is [System.Collections.IDictionary]) {
        foreach ($key in $Object.Keys) {
            if ([string]$key -ieq $Name) { return $Object[$key] }
        }
        return $null
    }

    $prop = $Object.PSObject.Properties[$Name]
    if ($prop) { return $prop.Value }

    # Graph SDK directory objects keep type-specific values in AdditionalProperties.
    $extra = $Object.PSObject.Properties['AdditionalProperties']
    if ($extra -and $extra.Value -is [System.Collections.IDictionary]) {
        foreach ($key in $extra.Value.Keys) {
            if ([string]$key -ieq $Name) { return $extra.Value[$key] }
        }
    }
    return $null
}

function ConvertTo-StringArray {
    [CmdletBinding()]
    param($Value)

    if ($null -eq $Value) { return , [string[]]@() }
    return , [string[]]@($Value | ForEach-Object { [string]$_ })
}

function Get-DaysSince {
    [CmdletBinding()]
    param(
        $Date,
        [Parameter(Mandatory)][datetime]$AsOf
    )

    if ($null -eq $Date) { return $null }
    return [int][math]::Floor(($AsOf - ([datetime]$Date)).TotalDays)
}

function ConvertTo-HtmlSafe {
    [CmdletBinding()]
    param($Value)

    if ($null -eq $Value) { return '' }
    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Format-AuditDate {
    [CmdletBinding()]
    param($Value)

    if ($null -eq $Value -or $Value -eq '') { return '' }
    return ([datetime]$Value).ToString('yyyy-MM-dd')
}

function Get-AuditContext {
    # Thin wrapper so tests can mock the connection state.
    [CmdletBinding()]
    param()
    Get-MgContext
}

function Assert-AuditConnection {
    <#
    .SYNOPSIS
        Fails fast when there is no Graph connection and warns when expected scopes are missing.
    #>
    [CmdletBinding()]
    param()

    $context = Get-AuditContext
    if (-not $context) {
        throw ('Not connected to Microsoft Graph. Run: Connect-MgGraph -Scopes (Get-AuditRequiredScope) ' +
            'or use -DemoMode to see the report with synthetic data.')
    }

    $granted = @($context.Scopes)
    $missing = @($script:RequiredScopes.Keys | Where-Object { $_ -notin $granted })
    if ($missing.Count -gt 0) {
        Write-Warning ("The current Graph session is missing these scopes: {0}. Related checks may be incomplete. " -f ($missing -join ', '))
    }
    return $context
}

function ConvertTo-SafeCsvRecord {
    <#
    .SYNOPSIS
        Flattens a record for CSV output and neutralises spreadsheet formula injection.
    .DESCRIPTION
        Display names and other directory values are controlled by users. A value that starts with
        =, +, - or @ can be executed as a formula when the CSV is opened in a spreadsheet, so those
        values are prefixed with an apostrophe.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory, ValueFromPipeline)]$Record)

    process {
        $out = [ordered]@{}
        foreach ($prop in $Record.PSObject.Properties) {
            $value = $prop.Value
            if ($value -is [datetime]) {
                $value = $value.ToString('yyyy-MM-dd HH:mm')
            }
            elseif ($value -is [System.Collections.IEnumerable] -and $value -isnot [string]) {
                $value = (@($value) | ForEach-Object { [string]$_ }) -join '; '
            }
            if ($value -is [string] -and $value -match '^[=+\-@\t\r]') {
                $value = "'" + $value
            }
            $out[$prop.Name] = $value
        }
        [pscustomobject]$out
    }
}

function Export-AuditCsv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [AllowEmptyCollection()][object[]]$Record
    )

    $safe = @($Record | ConvertTo-SafeCsvRecord)
    if ($safe.Count -eq 0) {
        # Write a header-less placeholder so downstream tooling always finds the file.
        Set-Content -Path $Path -Value '' -Encoding utf8
        return
    }
    $safe | Export-Csv -Path $Path -NoTypeInformation -Encoding utf8
}
