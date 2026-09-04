<#
.SYNOPSIS
    Exports carrier cloud product versions from StServer to a quoted CSV file.

.DESCRIPTION
    Runs the StProductVersions query against SQL Server and writes
    D:\Carrier-Cloud-Product-Versions.csv (by default). Every field is
    comma-separated and wrapped in double quotes. Embedded quotes are escaped
    by doubling them.

    Uses Windows integrated authentication unless -Username is supplied.

.EXAMPLE
    .\Export-CarrierCloudProductVersions.ps1

.EXAMPLE
    .\Export-CarrierCloudProductVersions.ps1 -Username 'reporting' -Password $cred.Password
#>
[CmdletBinding()]
param(
    [string]$Server = '10.3.0.10',
    [string]$Database = 'StServer',
    [string]$OutputPath = 'D:\Carrier-Cloud-Product-Versions.csv',
    [string]$Username,
    [SecureString]$Password
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$rowCount = 0

if ($Username -and -not $Password) {
    throw 'A -Password SecureString is required when -Username is specified.'
}

if ($Password -and -not $Username) {
    throw '-Username is required when -Password is specified.'
}

$query = @'
SELECT
    [Customer]    = a.CompanyName,
    [Platform]    = a.PlatformName,
    [Version]     = b.version,
    [LastChecked] = b.StWriteTime
FROM
    StProductVersions b WITH (NOLOCK)
JOIN
    StCustomerDetails a WITH (NOLOCK) ON a.stsid = b.stsid
ORDER BY
    [Customer], [platform]
'@

function ConvertTo-QuotedCsvField {
    param($Value)

    if ($null -eq $Value -or [DBNull]::Value.Equals($Value)) {
        return '""'
    }

    $text = if ($Value -is [datetime]) {
        $Value.ToString('yyyy-MM-dd HH:mm:ss')
    }
    else {
        [string]$Value
    }

    return '"' + ($text.Replace('"', '""')) + '"'
}

function Get-SqlConnectionString {
    $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $builder['Data Source'] = $Server
    $builder['Initial Catalog'] = $Database
    $builder['TrustServerCertificate'] = $true
    $builder['Encrypt'] = $true
    $builder['Connect Timeout'] = 30

    if ($Username) {
        $builder['Integrated Security'] = $false
        $builder['User ID'] = $Username
        if ($Password) {
            $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
            try {
                $builder['Password'] = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
            }
            finally {
                [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
            }
        }
    }
    else {
        $builder['Integrated Security'] = $true
    }

    return $builder.ConnectionString
}

Add-Type -AssemblyName System.Data | Out-Null

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

$connection = New-Object System.Data.SqlClient.SqlConnection (Get-SqlConnectionString)
$command = $connection.CreateCommand()
$command.CommandText = $query
$command.CommandTimeout = 300

try {
    Write-Host "Connecting to $Server / $Database ..."
    $connection.Open()

    $reader = $command.ExecuteReader()
    try {
        $fieldCount = $reader.FieldCount
        $headers = 0..($fieldCount - 1) | ForEach-Object { $reader.GetName($_) }

        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        $writer = New-Object System.IO.StreamWriter ($OutputPath, $false, $utf8NoBom)
        try {
            $writer.WriteLine(($headers | ForEach-Object { ConvertTo-QuotedCsvField $_ }) -join ',')

            $rowCount = 0
            while ($reader.Read()) {
                $fields = for ($i = 0; $i -lt $fieldCount; $i++) {
                    ConvertTo-QuotedCsvField $reader.GetValue($i)
                }
                $writer.WriteLine(($fields -join ','))
                $rowCount++
            }
        }
        finally {
            $writer.Dispose()
        }
    }
    finally {
        $reader.Dispose()
    }
}
finally {
    $connection.Dispose()
}

Write-Host "Wrote $rowCount row(s) to $OutputPath"
