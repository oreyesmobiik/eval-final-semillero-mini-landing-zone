# Copilot Log - Evaluacion Final Semillero

## Prompt 1
Se solicito crear una mini Landing Zone enterprise-scale acotada a una sola suscripcion, con Terraform modular, CI/CD con OIDC y despliegue en AKS.

## Diseno aplicado
- Estructura modular Terraform en infra/modules para network, acr, keyvault, aks y policy.
- Federated credentials con Managed Identities para pipelines de infraestructura y aplicacion.
- Red privada con Private Endpoints para ACR y Key Vault.
- AKS privado con OIDC issuer y workload identity habilitados.
- Politicas Azure Policy para negar recursos publicos.

## Por que estas decisiones (breve para bitacora)
- OIDC + Managed Identity elimina secretos estaticos en CI/CD y mejora trazabilidad.
- Terraform modular facilita reutilizacion, mantenimiento y separacion de responsabilidades.
- Private Endpoints y publicNetworkAccess deshabilitado reducen la superficie de exposicion.
- AKS privado con Azure RBAC y Workload Identity fortalece identidad y control de acceso.
- Azure Policy en alcance de Resource Group simula guardrails enterprise dentro de restriccion de una sola suscripcion.

## Advertencias de seguridad/obsolescencia detectadas y corregidas
- Corregido patron inseguro: no se uso ACR admin user ni access keys en pipelines.
- Corregido patron obsoleto: no se uso Service Principal con client secret; se uso OIDC.
- Corregido patron inseguro: bootstrap de state usa --auth-mode login, evitando lectura de storage account keys.
- Restriccion operativa clave: AKS privado no es alcanzable desde runners GitHub-hosted; se configuro app-cd con runner self-hosted en red privada.

## Validacion
- Diagnosticos del editor sin errores despues de los cambios.
- Validacion CLI de Terraform no ejecutada localmente porque el binario terraform no esta instalado en la terminal actual.

## Evidencia para bitacora
- Pipelines: .github/workflows/infra-ci.yml, infra-cd.yml, app-cd.yml
- IaC root: infra/main.tf
- Modulos: infra/modules/*
- App: app/Dockerfile + app/k8s/*

## Prompt 2
Se solicito robustecer bootstrap idempotente con -WhatIf, definir monorepo Terraform con modulos, red hub-spoke privada, workflow PR con OIDC y plan comentado, y observabilidad con alerta CPU + KQL.

## Cambios aplicados en Prompt 2
- Script bootstrap refactorizado con CmdletBinding SupportsShouldProcess, manejo de errores e idempotencia.
- Bootstrap ahora crea/omite recursos de estado y configura Federated Identity Credentials en App Registration existente.
- Modulo network migrado a hub-spoke con peering bidireccional y Private DNS Zones enlazadas a ambas VNets.
- Se agrego modulo monitoring con Log Analytics, diagnosticos AKS y alerta de metrica para CPU de nodos (>80 por defecto).
- Se agrego workflow .github/workflows/terraform-plan.yml para PR con OIDC, fmt/validate/plan y comentario automatico en PR.

## Validacion Prompt 2
- terraform fmt -recursive ejecutado correctamente.
- terraform init -backend=false ejecutado correctamente.
- terraform validate: Success! The configuration is valid.

## Estrategia Bitacora de Copilot
Contra-pregunta recomendada despues de cada bloque generado:
"Explicame que decisiones de diseno tomaste aqui y si hay alguna configuracion que deba ajustar para cumplir estrictamente con el principio de Least Privilege en Azure."

## Prompt 3
Se solicita documentar explicitamente en la bitacora los cambios principales y las decisiones tomadas.

## Cambios principales (consolidados)
- IaC base y modular creada en `infra` con modulos `network`, `aks`, `acr`, `keyvault` y `monitoring`.
- Script de arranque `bootstrap.ps1` reforzado para idempotencia, control de errores y soporte `-WhatIf`.
- Backend remoto de Terraform definido para `azurerm` y plantilla `backend.hcl.example` agregada.
- Red migrada a topologia hub-spoke con peering bidireccional y DNS privado para ACR/Key Vault.
- Observabilidad agregada: Log Analytics, diagnosticos de AKS, alerta de CPU de nodos (>80%), y KQL para errores HTTP 404/500.
- Pipeline PR `terraform-plan.yml` agregado con OIDC, validaciones Terraform y comentario automatico del plan en el Pull Request.

## Decisiones tomadas (consolidadas)
- Seguridad por defecto: OIDC en GitHub Actions y eliminacion de secretos estaticos en pipelines.
- Privacidad de plataforma: ACR/Key Vault sin acceso publico y conectividad por Private Endpoints.
- Gobernanza en alcance permitido: controles de Policy a nivel Resource Group por restriccion sin permisos de Tenant/MG.
- Reutilizacion y mantenibilidad: estructura modular para escalar ambientes sin duplicar codigo.
- Operacion realista: se documenta el requisito de runner self-hosted para despliegues contra AKS privado.

## Ajustes de Least Privilege pendientes de evaluar
- Reemplazar `Contributor` amplio de identidad de infraestructura por roles granulares por recurso cuando ya este estable el flujo.
- Revisar periodicidad de alertas y receptores para minimizar ruido operativo y permisos no necesarios.
