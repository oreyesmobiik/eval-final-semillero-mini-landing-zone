[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
param(
  [Parameter(Mandatory = $true)]
  [string]$SubscriptionId,

  [string]$TenantId,
  [string]$TfStateResourceGroup = "rg-tfstate-mini-lz",
  [string]$TfStateStorageAccountName,
  [string]$TfStateContainer = "tfstate",
  [switch]$DeleteTfState
)

$ErrorActionPreference = "Stop"
$Script:AzCliPython = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\python.exe"

function Invoke-AzCli {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments,
    [switch]$AllowFailure
  )

  if (Test-Path $Script:AzCliPython) {
    $output = & $Script:AzCliPython -IBm azure.cli @Arguments --only-show-errors 2>&1
  }
  else {
    $output = & az @Arguments --only-show-errors 2>&1
  }

  if (-not $AllowFailure -and $LASTEXITCODE -ne 0) {
    throw "Azure CLI command failed: az $($Arguments -join ' ')`n$output"
  }

  return $output
}

try {
  if (-not $TfStateStorageAccountName) {
    $hash = ($SubscriptionId -replace "-", "").Substring(0, [Math]::Min(8, ($SubscriptionId -replace "-", "").Length))
    $TfStateStorageAccountName = ("sttfstate$hash").ToLower()
  }

  $null = Invoke-AzCli -Arguments @("account", "show") -AllowFailure
  if ($LASTEXITCODE -ne 0) {
    if ($TenantId) {
      Invoke-AzCli -Arguments @("login", "--use-device-code", "--tenant", $TenantId) | Out-Null
    }
    else {
      Invoke-AzCli -Arguments @("login", "--use-device-code") | Out-Null
    }
  }

  Invoke-AzCli -Arguments @("account", "set", "--subscription", $SubscriptionId) | Out-Null

  $repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
  $infraDir = Join-Path $repoRoot "infra"

  if ($PSCmdlet.ShouldProcess($infraDir, "Terraform destroy (all managed resources)")) {
    terraform -chdir="$infraDir" init -backend-config="$infraDir\backend.hcl"
    terraform -chdir="$infraDir" destroy -auto-approve
  }

  if ($DeleteTfState) {
    if ($PSCmdlet.ShouldProcess($TfStateContainer, "Delete tfstate blob container")) {
      Invoke-AzCli -Arguments @(
        "storage", "container", "delete",
        "--name", $TfStateContainer,
        "--account-name", $TfStateStorageAccountName,
        "--auth-mode", "login",
        "--output", "none"
      ) -AllowFailure | Out-Null
    }

    if ($PSCmdlet.ShouldProcess($TfStateStorageAccountName, "Delete tfstate storage account")) {
      Invoke-AzCli -Arguments @(
        "storage", "account", "delete",
        "--name", $TfStateStorageAccountName,
        "--resource-group", $TfStateResourceGroup,
        "--yes",
        "--output", "none"
      ) -AllowFailure | Out-Null
    }

    if ($PSCmdlet.ShouldProcess($TfStateResourceGroup, "Delete tfstate resource group")) {
      Invoke-AzCli -Arguments @(
        "group", "delete",
        "--name", $TfStateResourceGroup,
        "--yes",
        "--no-wait",
        "--output", "none"
      ) -AllowFailure | Out-Null
    }
  }

  Write-Host "Cleanup completed." -ForegroundColor Green
}
catch {
  Write-Error "Cleanup failed: $($_.Exception.Message)"
  exit 1
}
