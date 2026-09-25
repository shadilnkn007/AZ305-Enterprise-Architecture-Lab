Install-WindowsFeature `
    -Name AD-Domain-Services `
    -IncludeManagementTools

Import-Module ADDSDeployment

Install-ADDSForest `
    -DomainName "contoso.local" `
    -DomainNetbiosName "CONTOSO" `
    -InstallDns `
    -Force
