param(
  [Parameter(Mandatory = $true)]
  [string]$SubscriptionId,

  [string]$Location = "eastus2",
  [string]$TfStateResourceGroup = "rg-tfstate-mini-lz",
  [string]$TfStateStorageAccountPrefix = "sttfstatemini",
  [string]$TfStateContainer = "tfstate"
)

$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host "`n==> $Message" -ForegroundColor Cyan
}

Write-Step "Validating Azure CLI session"
$null = az account show 2>$null
if ($LASTEXITCODE -ne 0) {
  az login --use-device-code | Out-Null
}

Write-Step "Setting active subscription"
az account set --subscription $SubscriptionId

$storageSuffix = (Get-Random -Maximum 9999).ToString("0000")
$storageAccountName = ("$TfStateStorageAccountPrefix$storageSuffix").ToLower()

Write-Step "Creating resource group for Terraform state"
az group create --name $TfStateResourceGroup --location $Location --output none

Write-Step "Creating storage account for remote state"
az storage account create `
  --name $storageAccountName `
  --resource-group $TfStateResourceGroup `
  --location $Location `
  --sku Standard_LRS `
  --allow-blob-public-access false `
  --min-tls-version TLS1_2 `
  --output none

Write-Step "Creating blob container for state"
az storage container create --name $TfStateContainer --account-name $storageAccountName --auth-mode login --output none

Write-Step "Bootstrap completed"
Write-Host "Use these GitHub repository variables:" -ForegroundColor Yellow
Write-Host "TFSTATE_RESOURCE_GROUP=$TfStateResourceGroup"
Write-Host "TFSTATE_STORAGE_ACCOUNT=$storageAccountName"
Write-Host "TFSTATE_CONTAINER=$TfStateContainer"
Write-Host "AZURE_SUBSCRIPTION_ID=$SubscriptionId"
Write-Host "AZURE_TENANT_ID=<your-tenant-id>"
Write-Host "AZURE_CLIENT_ID_INFRA=<from terraform output infra_client_id>"
Write-Host "AZURE_CLIENT_ID_APP=<from terraform output app_client_id>"
Write-Host "AKS_RESOURCE_GROUP=<from terraform output resource_group_name>"
Write-Host "AKS_NAME=<from terraform output aks_name>"
Write-Host "ACR_NAME=<from terraform output acr_name>"
