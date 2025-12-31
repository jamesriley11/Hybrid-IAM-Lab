<#
.SYNOPSIS
    GUI-based Active Directory user creation tool with username generation, department assignment, and temp password generation.

.DESCRIPTION
    Allows administrators to create new AD users through a simple Windows Forms GUI.
    Features include:
    - Username generation with collision checks
    - Optional truncation/alternative last name
    - Department selection with automatic group membership
    - Temporary password generation
    - Input validation and error checking
    - Export of temporary password to secure text file

.REQUIREMENTS
    - Powershell 5+
    - ActiveDirectory module installed
    - Appropriate AD permissions to create users and assign groups

.INPUTS
    User-entered first name, last name, optional alternative surname, and department

.OUTPUTS
    - AD user object created
    - Temporary password text file

.AUTHOR
    James Riley

.NOTES
    Replace placeholders with your own environment details before use
#>

# 1. Load .NET Assemblies for GUI
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# 2. Initialise Windows Form and GUI objects
$form             = New-Object System.Windows.Forms.Form
$form.ClientSize  = '400,400'
$form.text        = "Create New User"
$form.TopMost     = $false

# Label for first name input
$l_firstName          = New-Object System.Windows.Forms.Label
$l_firstName.text     = "First Name: "
$l_firstName.Width    = 110
$l_firstName.Height   = 20
$l_firstName.location = New-Object System.Drawing.Point(38,68)
$l_firstName.font     = 'Microsoft Sans Serif,10'

# Label for last name input
$l_lastName          = New-Object System.Windows.Forms.Label
$l_lastName.text     = "Last Name: "
$l_lastName.Width    = 110
$l_lastName.Height   = 20
$l_lastName.location = New-Object System.Drawing.Point(38,100)
$l_lastName.font     = 'Microsoft Sans Serif,10'

# Label for department input
$l_department          = New-Object System.Windows.Forms.Label
$l_department.text     = "Department: "
$l_department.Width    = 115
$l_department.Height   = 25
$l_department.location = New-Object System.Drawing.Point(38,132)
$l_department.font     = 'Microsoft Sans Serif,10'

# Textbox for first name input
$txt_firstName            = New-Object System.Windows.Forms.TextBox
$txt_firstName.multiline  = $false
$txt_firstName.width      = 100
$txt_firstName.height     = 20
$txt_firstName.location   = New-Object System.Drawing.Point(170,68)
$txt_firstName.font       = 'Microsoft Sans Serif,10'
$form.Controls.Add($txt_firstName)

# Textbox for last name input
$txt_lastName             = New-Object System.Windows.Forms.TextBox
$txt_lastName.multiline   = $false
$txt_lastName.width       = 100
$txt_lastName.height      = 20
$txt_lastName.location    = New-Object System.Drawing.Point(170,100)
$txt_lastName.font        = 'Microsoft Sans Serif,10'
$form.Controls.Add($txt_firstName)

# Textbox for alternative surname input
$txt_altsurname = New-Object System.Windows.Forms.TextBox
$txt_altsurname.Multiline = $false
$txt_altsurname.width = 100
$txt_altsurname.height = 20
$txt_altsurname.location = New-Object System.Drawing.Point(38, 205)
$txt_altsurname.Enabled = $false
$form.Controls.Add($txt_altsurname)

# ComboBox/Drop-Down for department selection
$CombDept = New-Object System.Windows.Forms.ComboBox
$CombDept.width = 150
$CombDept.height = 25
$CombDept.location = New-Object System.Drawing.Point(170,132)
$CombDept.Font = 'Microsoft Sans Serif,10'
$CombDept.DropDownStyle = 'DropDownList'
$CombDept.Items.AddRange(@("Finance", "HR", "IT"))
$CombDept.Text = ""
$CombDept.SelectedIndex = -1
$form.Controls.Add($CombDept)
$DepartmentGroups = @{
    "Finance" = @("G-Finance Users")
    "HR" = @("G-HR Users")
    "IT" = @("G-IT Users")
}

# Checkbox for alternative surname
$chkAltSurname = New-Object System.Windows.Forms.CheckBox
$chkAltSurname.Text = "Use alternative/truncated last name?"
$chkAltSurname.width = 2000
$chkAltSurname.location = New-Object System.Drawing.Point(38,180)
$chkAltSurname.font = 'Microsoft Sans Serif,10'
$chkAltSurname.Add_CheckedChanged({$txt_altsurname.Enabled = $chkAltSurname.Checked})

# Button to Run Script
$RunScript = New-Object System.Windows.Forms.Button
$RunScript.text = "Create"
$RunScript.width = 290
$RunScript.height = 45
$RunScript.location = New-Object System.Drawing.Point(50,300)
$RunScript.Font = 'Microsoft Sans Serif,10'
$RunScript.Add_Click({

# Function: Generate_Username
# Purpose: Generate a unique username based on first and last name
# Handles collisions by truncating first name and appending numbers
# Returns: String - generated username or "NULL" if unable to generate
function Generate_Username{
    param(
    [String]$firstname,
    [String]$surname
    )
    $firstname = $firstname.ToLower() 
    $surname = $surname.ToLower()
    $candidate = "NULL"
    $max_length = 20

    $fullName = $firstname + $surname
    If ($fullName.Length -gt $max_length){
        for ($i = 1; $i -le ($firstname.Length - 1); $i++){
        $candidate = $firstname.Substring(0,$i) + $surname

        if (-not (Get-ADUser -Filter "samAccountName -eq '$candidate'" -ErrorAction SilentlyContinue)){
            return $candidate}
        }
        
        $counter = 1
        $fullname = $firstname.Substring(0,$firstname.Length - 1) + $surname
        while ($counter -lt 10){
            $candidate = $fullname + $counter
            if (-not (Get-ADUser -Filter "samAccountName -eq '$candidate'" -ErrorAction SilentlyContinue)){
                return $candidate}
        $counter++
        }
    }
    else{
        for ($i = 1; $i -le $firstname.Length; $i++){
            $candidate = $firstname.Substring(0,$i) + $surname

            if (-not (Get-ADUser -Filter "samAccountName -eq '$candidate'" -ErrorAction SilentlyContinue)){
                return $candidate}
            }
        
            $counter = 1
            $fullname = $firstname + $surname
            while ($counter -le 10){
                $candidate = $fullname + $counter
                if (-not (Get-ADUser -Filter "samAccountName -eq '$candidate'" -ErrorAction SilentlyContinue)){
                    return $candidate}
            $counter++
            }
    }
    return "NULL"
}

# Function: Check_Inputs
# Purpose: Validate first name, last name, and optional alt surname
# Shows GUI error message for any invalid input
# Returns: $false if all inputs are valid, otherwise exits with message box
function Check_Inputs{
    param(
    [String]$firstname,
    [String]$surname,
    [String]$altsurname = ""
    )

    # Checks both a first name and surname has been entered
    if ($firstname.length -eq 0 -or $surname.Length -eq 0){
    [System.Windows.MessageBox]::Show("One of the textboxes are empty. Please ensure all information is complete", 'Error', 'OK', 'Error')
    return}
    # Checks both first name and surname don't exceed 256 attribute length limit
    elseif ($firstname.length -gt 256 -or $surname.Length -gt 256){
    [System.Windows.MessageBox]::Show("One of the textboxes are empty. Please ensure all information is complete", 'Error', 'OK', 'Error')
    return}
    # Checks whether alternative surname is being used unnecessarily
    elseif ($surname.length -lt 15 -and $altsurname -ne ""){
    [System.Windows.MessageBox]::Show("Surname is suitable length. Alternative surname not required", 'Error', 'OK', 'Error')
    return}
    # Checks whether alternative surname is not being used necessarily
    elseif($surname.Length -gt 15 -and $altsurname -eq ""){
    [System.Windows.MessageBox]::Show("Surname is too long (>15 chars). Please use a secondary truncated surname", 'Error', 'OK', 'Error')
    return}
    # Checks both surname and alternative surname don't exceed org username limit of 15
    elseif($surname.Length -gt 15 -and $altsurname.length -gt 15){
    [System.Windows.MessageBox]::Show("Alt surname is too long (>15 chars). Alt surname should be truncated", 'Error', 'OK', 'Error')
    return}
    # Checks firstname only contains alphabetical, spaces, or hyphen characters
    elseif ($firstname -notmatch '^[A-Za-z]+([ -][A-Za-z]+)*$'){
    [System.Windows.MessageBox]::Show("The first name contains invalid characters. Please ensure name is correct", 'Error', 'OK', 'Error')
    return}
    # Checks surname only contains alphabetical, spaces, or hyphen characters
    elseif ($surname -notmatch '^[A-Za-z]+([ -][A-Za-z]+)*$'){
    [System.Windows.MessageBox]::Show("The last name contains invalid characters. Please ensure name is correct", 'Error', 'OK', 'Error')
    return}
    # Checks alternative surname only contains alphabetical, spaces, or hyphen characters
    elseif ($altsurname -ne "" -and $surname -notmatch '^[A-Za-z]+([ -][A-Za-z]+)*$' -and $altsurname -notmatch '^[A-Za-z]+([ -][A-Za-z]+)*$'){
    [System.Windows.MessageBox]::Show("The last name contains invalid characters. Please ensure name is correct", 'Error', 'OK', 'Error')
    return}
    
    return $false
}

# Function: Create_Temp_Password
# Purpose: Generate a random 10-character temporary password
# Returns: String which will become user's initial password
function Create_Temp_Password{
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[{]}\|;:,<.>/?'
    $password = -join (1..10 | ForEach-Object {
        $i = Get-Random -Minimum 0 -Maximum $chars.Length
        $chars[$i]
        })
    return $password
}

# Function: Capitalise_Names
# Purpose: Capitalises name for uniform format, including hyphenated names
# Returns: String with leading letters capitalised
function Capitalise_Names{
    param(
    [String]$Name
    )

    $words = $Name -split ' '
    $capitalisedWords = @()

    foreach ($word in $words){
        if ($word.Length -eq 0){continue}
        
        $subWords = $word -split '-'
        $capitalisedSubWords = @()
        foreach($subword in $subWords){
            if ($subword.Length -gt 0){$capitalisedSubWords += $subword.Substring(0,1).ToUpper() + $subword.SubString(1).ToLower()}
        }

        $capitalisedWord = ($capitalisedSubWords -join '-')
        $capitalisedWords += $capitalisedWord
    }
    return ($capitalisedWords -join ' ')
}


Import-Module ActiveDirectory

# 1. Trim inputs and validate department
$firstName = $txt_firstName.Text.Trim()
$surname = $txt_lastName.Text.Trim()
$Department = $CombDept.SelectedItem
if (-not $Department){
    [System.Windows.MessageBox]::Show("No department selected. Please ensure a department is chosen", 'Error', 'OK', 'Error')
    return}

# 2. Check inputs meet format criteria and generate unique username
If ($chkAltSurname.Checked){
    $altSurname = $txt_altsurname.Text.Trim()
    $checkInputs = Check_Inputs -firstname $firstName -surname $surname -altsurname $altSurname
    If ($checkInputs -eq "OK"){return}
    $samAccountName = Generate_Username -firstName $firstName -surname $altSurname}
else{
    $checkInputs = Check_Inputs -firstname $firstName -surname $surname
    If ($checkInputs -eq "OK"){return}
    $samAccountName = Generate_Username -firstName $firstName -surname $surname}

If ($samAccountName -eq "NULL"){
    [System.Windows.MessageBox]::Show("Couldn't generate username. This typically happens due to too many users with same username.", 'Error', 'OK', 'Error')
    return}

# 3. Capitalise names to match uniform format
$firstName = Capitalise_Names -Name $firstName
$surname = Capitalise_Names -Name $surname

# 4. Confirm user creation
$msgBoxBody = "Are you sure you want to create new user ''$firstname $surname'' with username ''$samAccountName''?"
$msgBoxInput = [System.Windows.MessageBox]::Show($msgBoxBody, 'Are you sure?', 'YesNoCancel', 'Warning')

switch($msgBoxInput){
'Yes'{
        # 5. Create AD user, set name, UPN, department, temporary password and assign to department groups
        # UPN placeholder will need to be updated
        $fullName = $firstName + " " + $surname
        $upn = $samAccountName + "@REDACTED.DOMAIN.com"
        $TempPassword = Create_Temp_Password
        $securePwd = ConvertTo-SecureString $TempPassword -AsPlainText -Force
        New-ADUser -Name $fullName -SamAccountName $samAccountName -AccountPassword $securePwd -Enabled $true -Path "OU=Employees,DC=contoso,DC=local" -Department $Department -ChangePasswordAtLogon $true
        Set-ADUser -Identity $samAccountName -GivenName $firstName -surname $surname -DisplayName $fullName -UserPrincipalName $upn
        foreach ($group in $DepartmentGroups[$Department]){Add-ADGroupMember -Identity $group -Members $samAccountName}

        # 6. Export temporary password to text file
        # Output path placeholder will need to be updated
        $file_contents = "The temporary password for '$samAccountName' is `n$TempPassword"
        $FilePath = "C:\PATH\TO\OUTPUT\$samAccountName.txt"
        Set-Content -Path $FilePath -Value $file_contents -Encoding UTF8

        # 7. Reset form fields
        $txt_firstName.Text = ""
        $txt_lastName.Text = ""
        $txt_altsurname.Text = ""
        $CombDept.SelectedIndex = -1
        $chkAltSurname.Checked = $false
    }
'Cancel'{
        # 5. Reset form fields
        $txt_firstName.Text = ""
        $txt_lastName.Text = ""
        $txt_altsurname.Text = ""
        $CombDept.SelectedIndex = -1
        $chkAltSurname.Checked = $false
    }
}})

$form.Controls.AddRange(@($l_firstName, $l_lastName, $l_department, $txt_firstName, $txt_lastName, $txt_altsurname, $CombDept, $RunScript, $chkAltSurname))
[void]$form.ShowDialog() 
