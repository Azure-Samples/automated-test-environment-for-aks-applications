## Automated Test Environment for AKS Applications Changelog

<a name="1.0.0"></a>
# 1.0.0 (2020-08-03)

*Features*
* Create/Delete `kind` cluster in CI environment
* Optional - [Azure Key Vault Provider for Secrets Store CSI Driver](https://github.com/Azure/secrets-store-csi-driver-provider-azure) [installation](https://github.com/Azure/secrets-store-csi-driver-provider-azure#install-the-secrets-store-csi-driver-and-the-azure-keyvault-provider) and [configuration](https://github.com/Azure/secrets-store-csi-driver-provider-azure/blob/master/docs/service-principal-mode.md)
* Optional - [Azure Container Registry (ACR) Image Pull Secret](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-kubernetes#create-an-image-pull-secret)
* Install `helm` charts of application (values needed for integration test environment can be overwritten easily)
* Validate if the respective Kubernetes `pods` are up and running (multiple `pods` can be provided that are having selector - `app.kubernetes.io/name`)
* [Port-Froward](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/#forward-a-local-port-to-a-port-on-the-pod) the respective Kubernetes `services` needed to perform integration testing (multiple `services` can be provided and the respective local ports will be starting from `8080` to `808[number of services]` maintaining the order as provided)


*Bug Fixes*
* N/A

*Breaking Changes*
* N/A