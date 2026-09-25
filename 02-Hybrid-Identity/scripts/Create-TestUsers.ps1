Import-Module ActiveDirectory

$domain = "DC=contoso,DC=local"

New-ADUser `
    -Name "Alice Admin" `
    -GivenName "Alice" `
    -Surname "Admin" `
    -SamAccountName "alice" `
    -UserPrincipalName "alice@contoso.local" `
    -AccountPassword (Read-Host "Enter password for Alice" -AsSecureString) `
    -Enabled $true `
    -Path "CN=Users,$domain"

New-ADUser `
    -Name "Bob User" `
    -GivenName "Bob" `
    -Surname "User" `
    -SamAccountName "bob" `
    -UserPrincipalName "bob@contoso.local" `
    -AccountPassword (Read-Host "Enter password for Bob" -AsSecureString) `
    -Enabled $true `
    -Path "CN=Users,$domain"
