# Reporte de Cumplimiento de Entregables

Fecha de revision: 2026-05-05
Repositorio: eval-final-semillero-mini-landing-zone

## Resumen ejecutivo

- Estado general: Mayormente conforme (con pendientes de configuracion GitHub fuera del repositorio).
- Fortalezas: IaC modular, OIDC en pipelines, AKS privado, ACR/Key Vault privados, bootstrap idempotente con `-WhatIf`, bitacora de Copilot.
- Brechas principales: proteccion de rama `main` y `required reviewer` de environment en GitHub (configuracion externa).

## 3.1 Repositorio GitHub

1. Branch protection en `main`: pull request obligatorio, al menos un reviewer y status checks de CI.
- Estado: Parcial.
- Evidencia: intento de automatizacion local bloqueado porque no existe `gh` CLI en el entorno.
- Nota: debe configurarse en GitHub UI o con `gh` una vez instalada.

2. Estructura monorepo: `/infra/terraform`, `/app`, `/.github/workflows`, `/docs`.
- Estado: Parcial.
- Evidencia actual:
  - `infra/` (IaC Terraform)
  - `app/`
  - `.github/workflows/`
  - `docs/`
- Observacion: la ruta exacta requerida menciona `/infra/terraform`; en este repo el root Terraform esta en `infra/`.

3. README con diagrama de arquitectura (Mermaid u otro) generado o asistido con Copilot.
- Estado: Cumple.
- Evidencia: `README.md` (raiz) incluye diagrama Mermaid y documentacion general.

## 3.2 Infraestructura como codigo - Terraform

1. Estado remoto en Storage Account creado por bootstrap con PowerShell Az.
- Estado: Cumple.
- Evidencia: `scripts/bootstrap.ps1` crea RG, Storage Account, Container y genera `infra/backend.hcl`.

2. Modulos reutilizables: `network`, `aks`, `acr`, `keyvault`, `monitoring` y `policy`.
- Estado: Cumple.
- Evidencia: `infra/modules/network`, `infra/modules/aks`, `infra/modules/acr`, `infra/modules/keyvault`, `infra/modules/monitoring`, `infra/modules/policy`.

3. Workload Identity Federation (OIDC) entre GitHub y Azure. Sin secretos de service principal en repo.
- Estado: Cumple.
- Evidencia: `azure/login@v2` con `id-token: write` y variables en:
  - `.github/workflows/terraform-plan.yml`
  - `.github/workflows/terraform-apply.yml`
  - `.github/workflows/app-build-deploy.yml`

4. `terraform fmt`, `validate` y `plan` limpios y reproducibles.
- Estado: Cumple.
- Evidencia: pipeline PR ejecuta `fmt`, `validate`, `plan` en `.github/workflows/terraform-plan.yml`.
- Evidencia adicional: ejecuciones locales exitosas de `validate/plan/apply` en entorno del evaluado.

## 3.3 Plataforma desplegada

1. VNet hub-spoke con hub (Private DNS Zones y Bastion opcional). Spoke con subnets para AKS y Private Endpoints.
- Estado: Cumple (segun IaC declarada).
- Evidencia: modulo `infra/modules/network` (topologia hub-spoke, subnets AKS/PE, DNS privado).

2. AKS privado con node pool de sistema y de usuario, integrado con ACR mediante managed identity.
- Estado: Cumple (segun IaC declarada).
- Evidencia: modulo `infra/modules/aks` y asociaciones con ACR desde root `infra/main.tf`.

3. Key Vault con Private Endpoint; secretos consumidos via CSI driver o workload identity.
- Estado: Cumple.
- Evidencia:
  - Key Vault + Private Endpoint en `infra/modules/keyvault`.
  - Secreto bootstrap `miniapp-config` en Key Vault.
  - Consumo en workload via CSI: `app/k8s/secretproviderclass.yaml` y montaje en `app/k8s/deployment.yaml`.

4. Log Analytics y alertas: una metrica (CPU nodo AKS) y una alerta de logs KQL sobre Container Insights.
- Estado: Cumple.
- Evidencia: en `infra/modules/monitoring/main.tf` existen:
  - `azurerm_monitor_metric_alert` para CPU de nodos AKS.
  - `azurerm_monitor_scheduled_query_rules_alert_v2` para logs KQL de errores HTTP.
  - `azurerm_monitor_diagnostic_setting` para AKS, Key Vault y NSGs hacia Log Analytics.

## 3.4 Aplicacion contenerizada

1. Aplicacion minima y Dockerfile multi-stage.
- Estado: Cumple.
- Evidencia: `app/Dockerfile`.

2. Imagen en ACR y despliegue Deployment + Service en AKS.
- Estado: Cumple.
- Evidencia:
  - Build/push: `.github/workflows/app-build-deploy.yml`
  - Deployment/Service: `app/k8s/deployment.yaml`, `app/k8s/service.yaml`.

## 3.5 Pipelines GitHub Actions

1. `terraform-plan.yml` en PR: fmt, validate, plan y comentario en PR.
- Estado: Cumple.
- Evidencia: `.github/workflows/terraform-plan.yml`.

2. `terraform-apply.yml` en push a rama principal, con environment prod y required reviewer.
- Estado: Parcial.
- Evidencia: existe `.github/workflows/terraform-apply.yml` con trigger en rama principal (`main`/`master`) y `environment: production`.
- Brecha: required reviewer depende de configuracion del Environment en GitHub (fuera del codigo).

3. `app-build-deploy.yml` para build, push y deploy.
- Estado: Cumple.
- Evidencia: existe `.github/workflows/app-build-deploy.yml` con build/push/deploy.

4. Login a Azure mediante OIDC, sin credenciales de larga duracion.
- Estado: Cumple.
- Evidencia: `azure/login@v2` + `id-token: write` en workflows.

## 3.6 Script PowerShell de operacion

1. Script parametrizado e idempotente: bootstrap tfstate, federation credential y RBAC minimo.
- Estado: Cumple.
- Evidencia: `scripts/bootstrap.ps1` crea tfstate, federated credentials y asigna `Storage Blob Data Contributor` de forma idempotente.

2. Manejo de errores y soporte `-WhatIf`. Falla con mensaje claro si recursos ya existen.
- Estado: Cumple en gran parte.
- Evidencia: `CmdletBinding(SupportsShouldProcess = $true)`, `try/catch`, mensajes de omision cuando recursos existen.
- Nota: actualmente cuando recursos existen se omiten (idempotencia), no se fuerza fallo; esto es consistente con idempotencia pero no literal con "falla".

## 3.7 Bitacora de uso de Copilot

1. Archivo `docs/copilot-log.md` con al menos ocho prompts representativos.
- Estado: Cumple.
- Evidencia: `docs/copilot-log.md` incluye 8 prompts numerados.

2. Para cada prompt: prompt/intencion, resumen sugerido por Copilot, aceptado/rechazado/refactorizado con justificacion.
- Estado: Cumple.
- Evidencia: cada entrada del archivo usa el formato completo solicitado.

3. Casos obligatorios (Terraform module, KQL, Dockerfile, workflow, PowerShell, y un error de Copilot corregido).
- Estado: Cumple.
- Evidencia: cubierto explicitamente en prompts 1, 2, 3, 4, 5 y 6.

## Acciones de cierre recomendadas (en orden)

1. Configurar branch protection en GitHub para `main`:
- Require pull request before merging.
- Required approvals: 1.
- Required status checks: `terraform-plan` (y opcionalmente `infra-ci` si aplica).

2. Crear `README.md` en la raiz con:
- descripcion del proyecto,
- diagrama Mermaid,
- prerequisitos,
- flujo CI/CD,
- instrucciones de despliegue y validacion.
- Estado: completado en esta sesion.

3. Completar observabilidad:
- agregar alerta de logs con KQL en `infra/modules/monitoring` usando `azurerm_monitor_scheduled_query_rules_alert_v2`.
- Estado: completado en esta sesion.

4. Alinear nombres de workflows con rubrica (o documentar equivalencia):
- Estado: completado en esta sesion.

5. Completar `docs/copilot-log.md` hasta cubrir de forma explicita los 8 prompts y todos los casos obligatorios.
- Estado: completado en esta sesion.

6. Revisar `scripts/bootstrap.ps1` para incluir (si se exige literal) asignacion RBAC minima de forma explicita.
- Estado: completado en esta sesion.

7. Validar observabilidad extendida (AKS + Key Vault + NSGs) en Log Analytics.
- Estado: completado en esta sesion.

8. Confirmar tercera policy asignada en alcance de Resource Group.
- Estado: completado en esta sesion.

## Estado de la accion 1 (branch protection)

- Intento automatizado realizado: fallido por falta de `gh` CLI en el entorno local.
- Comando intentado:

```powershell
gh api -X PUT "/repos/:owner/:repo/branches/main/protection" -F required_status_checks.contexts='["terraform-plan"]' -F enforce_admins=true -F required_pull_request_reviews.dismiss_stale_reviews=true -F required_pull_request_reviews.required_approving_review_count=1 -F restrictions.users='[]' -F restrictions.teams='[]'
```

- Siguiente paso para cerrar accion 1:
  - instalar `gh` CLI y autenticar `gh auth login`, o
  - configurar la regla manualmente en GitHub Settings > Branches.
