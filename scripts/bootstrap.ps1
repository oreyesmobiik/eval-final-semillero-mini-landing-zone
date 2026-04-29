[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
param(
  [Parameter(Mandatory = $true)]
  [string]$SubscriptionId,

  [Parameter(Mandatory = $true)]
  [string]$TenantId,

  [Parameter(Mandatory = $true)]
  [string]$ServicePrincipalAppId,

  [Parameter(Mandatory = $true)]
  [string]$GitHubOrg,

  [Parameter(Mandatory = $true)]
  [string]$GitHubRepo,

  [string]$GitHubBranch = "main",
  [string]$Location = "eastus2",
  [string]$TfStateResourceGroup = "rg-tfstate-mini-lz",
  [string]$TfStateStorageAccountName,
  [string]$TfStateContainer = "tfstate"
)

$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Invoke-AzCli {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments,
    [switch]$AllowFailure
  )

  $output = & az @Arguments --only-show-errors 2>&1
  if (-not $AllowFailure -and $LASTEXITCODE -ne 0) {
    throw "Azure CLI command failed: az $($Arguments -join ' ')`n$output"
  }

  return $output
}

function Ensure-FederatedCredential {
  param(
    [Parameter(Mandatory = $true)]
    [string]$AppId,
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [Parameter(Mandatory = $true)]
    [string]$Subject
  )

  $existing = Invoke-AzCli -Arguments @(
    "ad", "app", "federated-credential", "list",
    "--id", $AppId,
    "--query", "[?name=='$Name'].name | [0]",
    "-o", "tsv"
  ) -AllowFailure

  if ($existing) {
    Write-Host "Federated credential '$Name' ya existe. Omitiendo."
    return
  }

  $payload = @{
    name        = $Name
    issuer      = "https://token.actions.githubusercontent.com"
    subject     = $Subject
    description = "GitHub Actions OIDC"
    audiences   = @("api://AzureADTokenExchange")
  } | ConvertTo-Json -Depth 4

  $tmpFile = Join-Path $env:TEMP "fic-$Name.json"
  $payload | Out-File -FilePath $tmpFile -Encoding ascii -Force

  try {
    if ($PSCmdlet.ShouldProcess("App Registration $AppId", "Create federated credential $Name")) {
      Invoke-AzCli -Arguments @(
        "ad", "app", "federated-credential", "create",
        "--id", $AppId,
        "--parameters", "@$tmpFile"
      ) | Out-Null
      Write-Host "Federated credential '$Name' creada."
    }
  }
  finally {
    Remove-Item -Path $tmpFile -Force -ErrorAction SilentlyContinue
  }
}

try {
  if (-not $TfStateStorageAccountName) {
    $hash = ($SubscriptionId -replace "-", "").Substring(0, [Math]::Min(8, ($SubscriptionId -replace "-", "").Length))
    $TfStateStorageAccountName = ("sttfstate$hash").ToLower()
  }

  Write-Step "Validating Azure CLI session"
  $null = Invoke-AzCli -Arguments @("account", "show") -AllowFailure
  if ($LASTEXITCODE -ne 0) {
    if ($PSCmdlet.ShouldProcess("Azure", "Login with device code")) {
      Invoke-AzCli -Arguments @("login", "--use-device-code", "--tenant", $TenantId) | Out-Null
    }
  }

  Write-Step "Setting active tenant and subscription"
  if ($PSCmdlet.ShouldProcess("Azure Context", "Set subscription $SubscriptionId")) {
    Invoke-AzCli -Arguments @("account", "set", "--subscription", $SubscriptionId) | Out-Null
  }

  Write-Step "Ensuring resource group for Terraform state"
  $rgExists = Invoke-AzCli -Arguments @("group", "exists", "--name", $TfStateResourceGroup, "-o", "tsv")
  if ($rgExists -eq "true") {
    Write-Host "Resource Group '$TfStateResourceGroup' ya existe. Omitiendo."
  }
  elseif ($PSCmdlet.ShouldProcess($TfStateResourceGroup, "Create resource group")) {
    Invoke-AzCli -Arguments @(
      "group", "create",
      "--name", $TfStateResourceGroup,
      "--location", $Location,
      "--output", "none"
    ) | Out-Null
  }

  Write-Step "Ensuring storage account for Terraform state"
  $saExists = Invoke-AzCli -Arguments @(
    "storage", "account", "show",
    "--name", $TfStateStorageAccountName,
    "--resource-group", $TfStateResourceGroup,
    "--query", "name",
    "-o", "tsv"
  ) -AllowFailure

  if ($saExists) {
    Write-Host "Storage Account '$TfStateStorageAccountName' ya existe. Omitiendo."
  }
  elseif ($PSCmdlet.ShouldProcess($TfStateStorageAccountName, "Create storage account")) {
    Invoke-AzCli -Arguments @(
      "storage", "account", "create",
      "--name", $TfStateStorageAccountName,
      "--resource-group", $TfStateResourceGroup,
      "--location", $Location,
      "--sku", "Standard_LRS",
      "--allow-blob-public-access", "false",
      "--allow-shared-key-access", "false",
      "--min-tls-version", "TLS1_2",
      "--output", "none"
    ) | Out-Null
  }

  Write-Step "Ensuring blob container for Terraform state"
  $containerExists = Invoke-AzCli -Arguments @(
    "storage", "container", "exists",
    "--name", $TfStateContainer,
    "--account-name", $TfStateStorageAccountName,
    "--auth-mode", "login",
    "--query", "exists",
    "-o", "tsv"
  )

  if ($containerExists -eq "true") {
    Write-Host "Container '$TfStateContainer' ya existe. Omitiendo."
  }
  elseif ($PSCmdlet.ShouldProcess($TfStateContainer, "Create blob container")) {
    Invoke-AzCli -Arguments @(
      "storage", "container", "create",
      "--name", $TfStateContainer,
      "--account-name", $TfStateStorageAccountName,
      "--auth-mode", "login",
      "--output", "none"
    ) | Out-Null
  }

  Write-Step "Ensuring Federated Identity Credentials on existing App Registration"
  $appExists = Invoke-AzCli -Arguments @(
    "ad", "app", "show",
    "--id", $ServicePrincipalAppId,
    "--query", "appId",
    "-o", "tsv"
  ) -AllowFailure

  if (-not $appExists) {
    throw "No se encontro un App Registration para el AppId '$ServicePrincipalAppId'."
  }

  Ensure-FederatedCredential -AppId $ServicePrincipalAppId -Name "gh-main" -Subject "repo:$GitHubOrg/$GitHubRepo:ref:refs/heads/$GitHubBranch"
  Ensure-FederatedCredential -AppId $ServicePrincipalAppId -Name "gh-pr" -Subject "repo:$GitHubOrg/$GitHubRepo:pull_request"

  Write-Step "Generating backend file for Terraform"
  $backendContent = @"
resource_group_name  = "$TfStateResourceGroup"
storage_account_name = "$TfStateStorageAccountName"
container_name       = "$TfStateContainer"
key                  = "mini-landing-zone.tfstate"
use_azuread_auth     = true
"@

  $backendPath = Join-Path $PSScriptRoot "..\infra\backend.hcl"
  if ($PSCmdlet.ShouldProcess($backendPath, "Write backend.hcl")) {
    $backendContent | Out-File -FilePath $backendPath -Encoding ascii -Force
  }

  Write-Step "Bootstrap completed"
  Write-Host "Use these GitHub repository variables:" -ForegroundColor Yellow
  Write-Host "TFSTATE_RESOURCE_GROUP=$TfStateResourceGroup"
  Write-Host "TFSTATE_STORAGE_ACCOUNT=$TfStateStorageAccountName"
  Write-Host "TFSTATE_CONTAINER=$TfStateContainer"
  Write-Host "AZURE_SUBSCRIPTION_ID=$SubscriptionId"
  Write-Host "AZURE_TENANT_ID=$TenantId"
  Write-Host "AZURE_CLIENT_ID_INFRA=$ServicePrincipalAppId"
}
catch {
  Write-Error "Bootstrap failed: $($_.Exception.Message)"
  exit 1
}
