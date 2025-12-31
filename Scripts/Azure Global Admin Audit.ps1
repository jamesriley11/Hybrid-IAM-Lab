<#
.SYNOPSIS
    Audit Global Administrators in Azure Entra ID (including PIM-eligible users) and export results to CSV log file.

.DESCRIPTION
    Connects to Microsoft Graph using certificate-based app authentication, retrieves permanent and PIM (Privileged Identity Management) eligible Global Administrators, and outputs a timestamped CSV report.

.REQUIREMENTS
    - PowerShell 7+
    - Microsoft.Graph module installed
    - App registration in Azure Entra ID with certificate authentication
    - Appropriate API permissions (RoleManagement.Read.Directory, Users.Read.All)

.INPUTS
    None - All parameters are defined in the script placeholders

.OUTPUT
    A CSV file containing:
    - Timestamp when the script was run
    - Display name
    - Email address
    - Account enabled status
    - Assignment type (Permanent/Eligible PIM)

.AUTHOR
    James Riley

.NOTES
    Placeholders for your own tenant/app/certificate information will need to be replaced, as well as a suitable output file path
#>


# 1. Authentication
# Connect to Microsoft.Graph using certificate-based app authentication
# (Placeholder values used for public repo)
$TenantID = "REDACTED"
$ClientId = "REDACTED"
$certThumbprint = "REDACTED"
Connect-MgGraph -TenantId $TenantID -ClientId $ClientId -CertificateThumbprint $certThumbprint

# 2. Retrieve Global Administrator role definition
$roleDefinitions = Get-MgRoleManagementDirectoryRoleDefinition -All
$globalAdminRole = $roleDefinitions | Where-Object {$_.DisplayName -eq "Global Administrator"}
if (-not $globalAdminRole){
    Write-Error "No 'Global Administrator' role could be found"
    return}

# 3. Retrieve permanently assigned Global Administrators
$permAssignments = Get-MgRoleManagementDirectoryRoleAssignment -Filter "roleDefinitionId eq '$($globalAdminRole.Id)'" -All
$permResults = Foreach ($cur in $permAssignments){
    $principal = Get-MgDirectoryObject -DirectoryObjectId $cur.PrincipalId
    if ($principal.AdditionalProperties.'@odata.type' -eq "#microsoft.graph.user"){
        $user = Get-MgUser -UserId $principal.Id -Property DisplayName, UserPrincipalName,AccountEnabled
        [PSCustomObject]@{
            "Display Name" = $user.DisplayName
            "Email Address" = $user.UserPrincipalName
            Enabled = $user.AccountEnabled
            Assignment = "Permanent"
        }
    }
}

# 4. Retrieve PIM-Eligible Global Administrators
$PIMAssignments = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -Filter "roleDefinitionId eq '$($globalAdminRole.Id)'" -All
$PIMResults = Foreach ($cur in $PIMAssignments){
    $principal = Get-MgDirectoryObject -DirectoryObjectId $cur.PrincipalId
    if ($principal.AdditionalProperties.'@odata.type' -eq "#microsoft.graph.user"){
        $user = Get-MgUser -UserId $principal.Id -Property DisplayName, UserPrincipalName,AccountEnabled
        [PSCustomObject]@{
            "Display Name" = $user.DisplayName
            "Email Address" = $user.UserPrincipalName
            Enabled = $user.AccountEnabled
            Assignment = "Eligible (PIM)"
        }
    }
}

# 5. Combining results and output
$allGlobalAdmins = $permResults + $PIMResults
$allGlobalAdmins | Sort-Object Assignment, DisplayName | Format-Table -AutoSize

# 6. Export results to CSV
# (placeholder values used for public repo)
$filetimestamp = Get-Date -Format "yyyy-MM-dd_HH.mm.ss"
$auditTimestamp = Get-Date -Format "HH:mm.ss 'on' dd MMMM yyyy"
$OutputPath = "C:\PATH\TO\OUTPUT\AdminAudit_$filetimestamp.csv"

"Audit taken at $auditTimestamp" | Out-File -FilePath $OutputPath -Encoding utf8
"Display Name,Email Address,Enabled,Assignment" | Out-File -FilePath $OutputPath -Append -Encoding utf8
$allGlobalAdmins | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Out-File -FilePath $OutputPath -Append -Encoding utf8