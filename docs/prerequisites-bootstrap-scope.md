# Prerrequisitos y Alcance de Bootstrap

Este documento aclara que debe existir previamente en Tenant/Suscripcion, que puede crear `scripts/bootstrap.ps1` y que corresponde a Terraform.

## 1. Prerrequisitos Minimos

### 1.1 En tu equipo local

- Azure CLI instalado y funcional.
- Terraform instalado y funcional.
- Sesion iniciada en Azure (`az login`) o permiso para usar `--use-device-code`.

### 1.2 En Azure Tenant/Suscripcion

- Suscripcion activa en estado `Enabled`.
- Registro de proveedores necesarios al menos para arranque:
  - `Microsoft.Storage` (obligatorio para backend tfstate).
- Un App Registration existente (valor `ServicePrincipalAppId`) para federacion OIDC.
- Service Principal existente asociado al App Registration.
- Permisos del usuario operador:
  - Crear Resource Group / Storage Account / Blob Container.
  - Crear Federated Credentials sobre el App Registration.
  - Crear Role Assignments (al menos para `Storage Blob Data Contributor` en storage tfstate).

## 2. Que SI crea scripts/bootstrap.ps1

El script `scripts/bootstrap.ps1` crea o asegura:

- Contexto de suscripcion activo (`az account set`).
- Resource Group de tfstate (`rg-tfstate-mini-lz` por defecto).
- Storage Account de tfstate (`sttfstate<hash-suscripcion>` por defecto).
- Blob Container de tfstate (`tfstate` por defecto).
- Federated Credentials para GitHub Actions:
  - `gh-main`
  - `gh-pr`
- RBAC minimo sobre storage tfstate:
  - `Storage Blob Data Contributor` al Service Principal.
- Archivo backend para Terraform:
  - `infra/backend.hcl`

Opcional (si se usa `-EnsureOperatorPermissions`):

- Asigna permisos al operador para cubrir precondiciones de entrega:
  - `Contributor` en la suscripcion.
  - `Storage Blob Data Contributor` sobre la Storage Account de tfstate.
  - Owner del App Registration (`ServicePrincipalAppId`) para administrar Federated Credentials.

## 3. Que NO crea bootstrap (y debe existir antes)

- El App Registration base (`ServicePrincipalAppId`) y su Service Principal.
- Branch protection / reviewers / environments en GitHub.
- Runner self-hosted para despliegue a AKS privado.
- Registro de todos los providers de Azure para toda la plataforma (eso se valida durante Terraform).

## 4. Que crea Terraform (infra/)

- Resource Group de plataforma.
- Identidades administradas para pipelines.
- Red hub-spoke y DNS privados.
- ACR privado.
- Key Vault privado y secreto bootstrap de app.
- AKS privado (pool de sistema + pool de usuario) y roles asociados.
- Monitoring (Log Analytics + alertas metricas y logs KQL).
- Policy assignments a nivel de Resource Group.

## 5. Flujo recomendado de ejecucion

1. Ejecutar bootstrap:

```powershell
./scripts/bootstrap.ps1 `
  -SubscriptionId "<subscription-id>" `
  -TenantId "<tenant-id>" `
  -ServicePrincipalAppId "<app-id>" `
  -GitHubOrg "<github-org>" `
  -GitHubRepo "<github-repo>"
```

Si tambien quieres que bootstrap asegure permisos del operador:

```powershell
./scripts/bootstrap.ps1 `
  -SubscriptionId "<subscription-id>" `
  -TenantId "<tenant-id>" `
  -ServicePrincipalAppId "<app-id>" `
  -GitHubOrg "<github-org>" `
  -GitHubRepo "<github-repo>" `
  -EnsureOperatorPermissions
```

Si no puede resolver automaticamente el objectId del operador, usar:

```powershell
./scripts/bootstrap.ps1 `
  -SubscriptionId "<subscription-id>" `
  -TenantId "<tenant-id>" `
  -ServicePrincipalAppId "<app-id>" `
  -GitHubOrg "<github-org>" `
  -GitHubRepo "<github-repo>" `
  -EnsureOperatorPermissions `
  -OperatorObjectId "<aad-object-id>"
```

2. Inicializar y desplegar Terraform:

```powershell
terraform -chdir="./infra" init -backend-config="./infra/backend.hcl"
terraform -chdir="./infra" validate
terraform -chdir="./infra" plan -out tfplan
terraform -chdir="./infra" apply -auto-approve tfplan
```

## 6. Notas operativas observadas en esta evaluacion

- Si `az` no esta en PATH, Terraform/Provider `azurerm` no puede autenticarse por Azure CLI.
- Si `Microsoft.Storage` no esta registrado, bootstrap falla al crear storage account de tfstate.
- Ejecutar scripts desde ruta raiz del repo para evitar errores de path relativo.
