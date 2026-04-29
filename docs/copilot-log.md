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
