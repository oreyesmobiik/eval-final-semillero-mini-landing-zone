# Mini Landing Zone Architecture (Single Subscription)

```mermaid
flowchart TD
  GH[GitHub Actions OIDC] --> INFRAID[UAMI Infra]
  GH --> APPID[UAMI App]

  INFRAID --> RG[Resource Group]
  RG --> VNET[VNet 10.50.0.0/16]
  VNET --> AKSSUBNET[AKS Subnet]
  VNET --> PESUBNET[Private Endpoint Subnet]

  RG --> ACR[Azure Container Registry Premium]
  RG --> KV[Key Vault]
  RG --> AKS[Private AKS Cluster]
  RG --> POLICY[Azure Policy Assignments]

  PESUBNET --> PEACR[Private Endpoint ACR]
  PESUBNET --> PEKV[Private Endpoint Key Vault]

  VNET --> DNSACR[Private DNS Zone privatelink.azurecr.io]
  VNET --> DNSKV[Private DNS Zone privatelink.vaultcore.azure.net]

  APPID --> ACRPUSH[AcrPush Role]
  APPID --> AKSWRITE[AKS RBAC Writer + Cluster User]

  AKS --> APP[Mini App Deployment]
  APP --> ILB[Internal Load Balancer Service]
```

## CAF Mapping (Scoped)

- Governance: Azure Policy assigned at resource group scope.
- Security: Private Endpoints, public network disabled for ACR and Key Vault, RBAC-only access.
- Identity: Managed identities with GitHub OIDC federation, no client secrets.
- Platform: Hub-and-spoke style reduced to one VNet due to single-subscription constraint.
- DevOps: CI/CD split for infrastructure and app deployment.
