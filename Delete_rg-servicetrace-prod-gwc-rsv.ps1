# Prompt the user for the vault name and subscription
$VaultName = Read-Host "Enter the name of the Recovery Services Vault"
$TargetSubscription = Read-Host "Enter the name of the Azure Subscription"

# Check if already signed in to the correct subscription
$currentSubscription = (Get-AzContext).Subscription.Name
if ($currentSubscription -ne $TargetSubscription) {
    Write-Output "Connecting to subscription $TargetSubscription..."
    Connect-AzAccount -Subscription $TargetSubscription
} else {
    Write-Output "Already connected to subscription $currentSubscription."
}

# Fetch the Recovery Services Vault
Write-Output "Fetching Recovery Services Vault..."
$vault = Get-AzRecoveryServicesVault -Name $VaultName
if (-not $vault) {
    Write-Output "Error: Vault '$VaultName' not found in subscription $TargetSubscription."
    exit
}
Write-Output "Vault found: $($vault.Name)"

# Set the vault context
Write-Output "Setting vault context..."
Set-AzRecoveryServicesVaultContext -Vault $vault

# Get all backup containers in the vault
Write-Output "Fetching backup containers..."
$backupContainers = Get-AzRecoveryServicesBackupContainer -VaultId $vault.ID -ContainerType AzureVM
if ($backupContainers.Count -eq 0) {
    Write-Output "No backup containers found."
} else {
    Write-Output "$($backupContainers.Count) backup container(s) found."

    # Process each container
    foreach ($container in $backupContainers) {
        Write-Output "Processing container: $($container.Name)..."

        # Get all backup items in the container with WorkloadType as AzureVM
        $backupItems = Get-AzRecoveryServicesBackupItem -VaultId $vault.ID -Container $container -WorkloadType AzureVM

        if ($backupItems.Count -gt 0) {
            Write-Output "Disabling backup protection for $($backupItems.Count) item(s)..."
            foreach ($item in $backupItems) {
                Write-Output "Disabling backup for item: $($item.Name)..."
                Disable-AzRecoveryServicesBackupProtection -Item $item -RemoveRecoveryPoints -Force
            }
        } else {
            Write-Output "No backup items found in container: $($container.Name)."
        }
    }
}

# Attempt to remove the Recovery Services Vault
Write-Output "Attempting to delete the Recovery Services Vault..."
Remove-AzRecoveryServicesVault -Name $VaultName -ResourceGroupName $vault.ResourceGroupName

Write-Output "Vault removal process completed."
