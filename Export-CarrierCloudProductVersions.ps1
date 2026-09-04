<#
.SYNOPSIS
    Exports carrier cloud product versions from StServer to a quoted CSV file.

.DESCRIPTION
    Runs the StProductVersions query against SQL Server and writes a CSV to
    the supplied output path. Every field is comma-separated and wrapped in
    double quotes. Embedded quotes are escaped by doubling them.

    SQL authentication uses a PSCredential loaded from cred.xml:

        $cred = Import-Clixml cred.xml

    Create that file once, as the same Windows user that will run the export:

        Get-Credential | Export-Clixml -Path .\cred.xml

.PARAMETER OutputPath
    Destination CSV file path.

.EXAMPLE
    .\Export-CarrierCloudProductVersions.ps1 'D:\Carrier-Cloud-Product-Versions.csv'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$OutputPath,

    [string]$Server = '10.3.0.10',
    [string]$Database = 'StServer',
    [string]$CredentialPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$rowCount = 0

if (-not $CredentialPath) {
    $CredentialPath = Join-Path $PSScriptRoot 'cred.xml'
}

if (-not (Test-Path -LiteralPath $CredentialPath)) {
    throw "Credential file not found: $CredentialPath. Create it with: Get-Credential | Export-Clixml -Path '$CredentialPath'"
}

$cred = Import-Clixml $CredentialPath

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
    $builder['Integrated Security'] = $false
    $builder['User ID'] = $cred.UserName
    $builder['Password'] = $cred.GetNetworkCredential().Password
    $builder['TrustServerCertificate'] = $true
    $builder['Encrypt'] = $true
    $builder['Connect Timeout'] = 30
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
    Write-Host "Connecting to $Server / $Database as $($cred.UserName) ..."
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
