# Carrier Cloud Product Versions

Exports customer platform versions from the **StServer** database on `10.3.0.10` to:

`D:\Carrier-Cloud-Product-Versions.csv`

The CSV is comma-separated. Every field, including headers, is wrapped in double quotes. Quotes inside a value are escaped by doubling them (`"` becomes `""`).

## Requirements

- A Windows machine that can reach `10.3.0.10`
- Permission to read the `StServer` database (Windows integrated authentication by default)
- Windows PowerShell 5.1 or PowerShell 7+

## Usage

From the repository folder:

```powershell
.\Export-CarrierCloudProductVersions.ps1
```

Or double-click `Export-CarrierCloudProductVersions.bat`.

### Optional parameters

| Parameter | Default | Purpose |
| --- | --- | --- |
| `-Server` | `10.3.0.10` | SQL Server host |
| `-Database` | `StServer` | Database name |
| `-OutputPath` | `D:\Carrier-Cloud-Product-Versions.csv` | CSV destination |
| `-Username` | *(Windows auth)* | SQL login, if not using integrated security |
| `-Password` | | SecureString password for `-Username` |

SQL authentication example:

```powershell
$cred = Get-Credential
.\Export-CarrierCloudProductVersions.ps1 -Username $cred.UserName -Password $cred.Password
```

A different output path:

```powershell
.\Export-CarrierCloudProductVersions.ps1 -OutputPath 'C:\Temp\Carrier-Cloud-Product-Versions.csv'
```
