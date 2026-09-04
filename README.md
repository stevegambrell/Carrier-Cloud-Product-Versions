# Carrier Cloud Product Versions

Exports customer platform versions from the **StServer** database on `10.3.0.10` to a CSV path you pass in.

The CSV is comma-separated. Every field, including headers, is wrapped in double quotes. Quotes inside a value are escaped by doubling them (`"` becomes `""`).

## Requirements

- A Windows machine that can reach `10.3.0.10`
- Windows PowerShell 5.1 or PowerShell 7+
- A `cred.xml` file next to the script, created by the same Windows user that will run the export

## Create credentials

Run this once on the machine (and as the Windows user) that will run the export:

```powershell
Get-Credential | Export-Clixml -Path .\cred.xml
```

Enter the SQL Server username and password when prompted. `Export-Clixml` encrypts the file with Windows DPAPI, so it cannot be used on another machine or by another user.

## Usage

```powershell
.\Export-CarrierCloudProductVersions.ps1 'D:\Carrier-Cloud-Product-Versions.csv'
```

Or double-click `Export-CarrierCloudProductVersions.bat`, which writes to `D:\Carrier-Cloud-Product-Versions.csv` unless you pass a different path:

```bat
Export-CarrierCloudProductVersions.bat D:\Carrier-Cloud-Product-Versions.csv
```

The script loads SQL credentials with:

```powershell
$cred = Import-Clixml cred.xml
```

### Parameters

| Parameter | Default | Purpose |
| --- | --- | --- |
| `-OutputPath` (required) | | Destination CSV file |
| `-Server` | `10.3.0.10` | SQL Server host |
| `-Database` | `StServer` | Database name |
| `-CredentialPath` | `cred.xml` next to the script | PSCredential XML from `Export-Clixml` |
