# Copilot Log - Evaluacion Final Semillero

Este archivo documenta prompts representativos usados durante la construccion del proyecto.
Cada entrada incluye: intencion, resumen de sugerencias, que se acepto, que se rechazo y que se refactorizo.

## Prompt 1 - Modulo Terraform (obligatorio)

- Prompt en editor:
	"Genera un modulo Terraform de red para una topologia hub-spoke con subred AKS, subred de private endpoints, peering bidireccional y DNS privado para ACR y Key Vault."
- Resumen de sugerencia Copilot:
	propuso VNet hub/spoke, subnets dedicadas y recursos de private DNS.
- Aceptado:
	estructura base de VNet/subnets y enlaces de DNS privado.
- Rechazado:
	uso de CIDR hardcoded en varias partes del modulo.
- Refactorizado y justificacion:
	se parametrizaron CIDR y nombres para reutilizacion entre ambientes.

## Prompt 2 - Workflow Terraform PR (obligatorio workflow)

- Prompt en editor:
	"Crea terraform-plan.yml para pull_request con OIDC, terraform fmt, validate, plan y comentario automatico en el PR."
- Resumen de sugerencia Copilot:
	genero workflow con azure/login, setup-terraform y comentario con github-script.
- Aceptado:
	secuencia `init -> fmt -> validate -> plan` y comentario de plan truncado.
- Rechazado:
	intento inicial de usar secretos de cliente para login.
- Refactorizado y justificacion:
	se cambio a federacion OIDC (`id-token: write`) para eliminar credenciales de larga duracion.

## Prompt 3 - Script PowerShell Bootstrap (obligatorio PowerShell)

- Prompt en editor:
	"Diseña bootstrap.ps1 idempotente con -WhatIf para crear backend tfstate, federated credentials y manejo de errores claro."
- Resumen de sugerencia Copilot:
	propuso funciones helper, `try/catch`, y `CmdletBinding(SupportsShouldProcess=$true)`.
- Aceptado:
	patron idempotente, soporte `-WhatIf`, y validacion de sesion Azure.
- Rechazado:
	comandos que obtenian llaves de storage account.
- Refactorizado y justificacion:
	se uso `--auth-mode login` y AAD auth para reducir riesgo de exponer llaves.

## Prompt 4 - Dockerfile multi-stage (obligatorio Dockerfile)

- Prompt en editor:
	"Genera Dockerfile multi-stage para app minima en Python, imagen final ligera y puerto 8080."
- Resumen de sugerencia Copilot:
	propuso builder + runtime final y comando de arranque para la app.
- Aceptado:
	estrategia multi-stage y dependencias en `requirements.txt`.
- Rechazado:
	sugerencia de ejecutar como root sin endurecimiento.
- Refactorizado y justificacion:
	se ajusto imagen final para minimizar superficie y mantener despliegue reproducible.

## Prompt 5 - Consulta KQL (obligatorio KQL)

- Prompt en editor:
	"Escribe una consulta KQL para detectar errores HTTP 404/500 en logs de pods del namespace miniapp y ordenarla por tiempo."
- Resumen de sugerencia Copilot:
	consulta sobre `ContainerLogV2` con filtros por namespace y patrones 404/500.
- Aceptado:
	filtro por namespace y proyeccion de columnas operativas.
- Rechazado:
	variante inicial demasiado amplia sin filtro de namespace.
- Refactorizado y justificacion:
	se agrego filtro estricto para evitar ruido y falsos positivos.

## Prompt 6 - Error de Copilot y correccion (obligatorio caso de error)

- Prompt en editor:
	"Genera el recurso de diagnostico para AKS con el proveedor azurerm actual."
- Resumen de sugerencia Copilot:
	uso de sintaxis antigua para diagnosticos que no coincidia con version del provider.
- Aceptado:
	intencion general del recurso.
- Rechazado:
	bloque desactualizado/deprecado en configuracion de logs.
- Refactorizado y justificacion:
	se migro a `azurerm_monitor_diagnostic_setting` compatible con `azurerm ~> 4.x`.

## Prompt 7 - Observabilidad y alertas

- Prompt en editor:
	"Agrega alerta de metrica para CPU de nodo AKS y alerta de logs basada en KQL usando Azure Monitor."
- Resumen de sugerencia Copilot:
	propuso `azurerm_monitor_metric_alert` y query KQL reutilizable.
- Aceptado:
	alerta de CPU y umbral parametrizado.
- Rechazado:
	ausencia inicial de recurso de alerta de logs.
- Refactorizado y justificacion:
	se agrego `azurerm_monitor_scheduled_query_rules_alert_v2` para cumplir rubrica de logs.

## Prompt 8 - Documentacion de cumplimiento

- Prompt en editor:
	"Documenta el cumplimiento por entregable con evidencia concreta, brechas y plan de cierre."
- Resumen de sugerencia Copilot:
	checklist por secciones 3.1 a 3.7, estado Cumple/Parcial y evidencias de archivos.
- Aceptado:
	estructura de reporte y lista de acciones de cierre.
- Rechazado:
	afirmaciones no verificables sobre configuraciones externas de GitHub.
- Refactorizado y justificacion:
	se marco como pendiente todo lo que depende de configuracion fuera del repositorio (branch protection/environment reviewers).

## Evidencia transversal

- Terraform root: `infra/main.tf`
- Modulos: `infra/modules/*`
- Workflows: `.github/workflows/terraform-plan.yml`, `.github/workflows/terraform-apply.yml`, `.github/workflows/app-build-deploy.yml`
- Script: `scripts/bootstrap.ps1`
- Dockerfile y manifests: `app/Dockerfile`, `app/k8s/*`
- Cumplimiento: `docs/compliance-report.md`
