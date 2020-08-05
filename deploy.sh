#/bin/bash
set +x
set +e

###########################################################################
# Usage: bash -f ./deploy.sh
#        Supported Options - 
#              --csi-driver-enabled=<yes/no> (default no, if yes provide following two parameters)
#              --csi-driver-sp-client-id=<Azure Service Principle ID, having access to Azure Key Vault>
#              --csi-driver-sp-client-secret=<Azure Service Principle Secret, having access to Azure Key Vault>
#              --acr-imagepullsecret-enabled=<yes/no> (default no, if yes provide following three parameters)
#              --acr-imagepullsecret-sp-client-id=<Azure Service Principle ID, having access to Azure Container Registry>
#              --acr-imagepullsecret-sp-client-secret=<Azure Service Principle Secret, having access to Azure Container Registry>
#              --acr-full-name=<Azure Container Registry full name ex. example.azurecr.io>
#              --helm-chart-path=<Helm Chart Folder Path or URL to .tgz file for the applications >
#              --helm-chart-release-name=<Helm Release Name>
#              --helm-chart-set-parameters=<","(comma) seprated Helm Set parameters needed to be overwritten for integration test env>
#              --kubectl-check-services=<","(comma) seprated Pod names needed to be check if up and running>
#              --kubectl-check-services-selector-label=<ex. app.kubernetes.io/name or name etc.> (default app.kubernetes.io/name)
#              --kubectl-port-forward-services=<","(comma) seprated Service names needed to port-forward for testing>
###########################################################################

# All Supported Arguments
ARGUMENT_LIST=(
   "csi-driver-enabled"
   "csi-driver-sp-client-id"
   "csi-driver-sp-client-secret"
   "acr-imagepullsecret-enabled"
   "acr-imagepullsecret-sp-client-id"
   "acr-imagepullsecret-sp-client-secret"
   "acr-full-name"
   "helm-chart-path"
   "helm-chart-release-name"
   "helm-chart-set-parameters"
   "kubectl-check-services"
   "kubectl-check-services-selector-label"
   "kubectl-port-forward-services"
)

# Read Arguments
opts=$(getopt \
    --longoptions "$(printf "%s:," "${ARGUMENT_LIST[@]}")" \
    --name "$(basename "$0")" \
    --options "" \
    -- "$@"
)

# Assign Values from Arguments
eval set --$opts
while [[ $# -gt 0 ]]; do
   case "$1" in
      --csi-driver-enabled)
         CSI_DRIVER_ENABLED=$(echo "$2" | tr '[:upper:]' '[:lower:]')
         shift 2
         ;;
      --csi-driver-sp-client-id)
         CSI_DRIVER_SP_CLIENT_ID=$2
         shift 2
         ;;
      --csi-driver-sp-client-secret)
         CSI_DRIVER_SP_CLIENT_SECRET=$2
         shift 2
         ;;
      --acr-imagepullsecret-enabled)
         ACR_IMAGEPULLSECRET_ENABLED=$(echo "$2" | tr '[:upper:]' '[:lower:]')
         shift 2
         ;;
      --acr-imagepullsecret-sp-client-id)
         ACR_IMAGEPULLSECRET_SP_CLIENT_ID=$2
         shift 2
         ;;
      --acr-imagepullsecret-sp-client-secret)
         ACR_IMAGEPULLSECRET_SP_CLIENT_SECRET=$2
         shift 2
         ;;
      --acr-full-name)
         ACR_FULL_NAME=$2
         shift 2
         ;;
      --helm-chart-path)
         HELM_CHART_PATH=$2
         shift 2
         ;;
      --helm-chart-release-name)
         HELM_CHART_RELEASE_NAME=$2
         shift 2
         ;;
      --helm-chart-set-parameters)
         HELM_CHART_SET_PARAMETERS=$(echo $2 | sed 's/,\ /,/g')
         shift 2
         ;;
      --kubectl-check-services)
         KUBECTL_CHECK_SERVICES=$(echo $2 | tr "," "\n")
         shift 2
         ;;
      --kubectl-check-services-selector-label)
         KUBECTL_CHECK_SERVICES_SELECTOR_LABEL=$2
         shift 2
         ;;
      --kubectl-port-forward-services)
         KUBECTL_PORT_FORWARD_SERVICES=$(echo $2 | tr "," "\n")
         shift 2
         ;;
      *)
         break
         ;;
   esac
done

# Assign Deafults
KUBECTL_CHECK_SERVICES_SELECTOR_LABEL=${KUBECTL_CHECK_SERVICES_SELECTOR_LABEL:-"app.kubernetes.io/name"}

if [[ "${CSI_DRIVER_ENABLED}" == "yes" ]]; then
   echo $(date -u) "[INFO] Installing CSI Driver ..."
   linux-amd64/helm repo add csi-secrets-store-provider-azure https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts
   linux-amd64/helm install csi-secrets-store-provider-azure/csi-secrets-store-provider-azure --generate-name --wait

   echo $(date -u) "[INFO] Creating CSI Driver Secret to get Secrets from AKV ..."
   ./kubectl create secret generic secrets-store-creds \
      --from-literal clientid="${CSI_DRIVER_SP_CLIENT_ID}" \
      --from-literal clientsecret="${CSI_DRIVER_SP_CLIENT_SECRET}"

   echo $(date -u) "[INFO] Sleeping 60s to make sure CSI Driver get provisioned .."
   sleep 60s
fi

if [[ "${ACR_IMAGEPULLSECRET_ENABLED}" == "yes" ]]; then
   echo $(date -u) "[INFO] Creating Image Pull Secret ..."
   ./kubectl create secret docker-registry imagepullsecret \
      --docker-server="https://${ACR_FULL_NAME}" \
      --docker-username="${ACR_IMAGEPULLSECRET_SP_CLIENT_ID}" \
      --docker-password="${ACR_IMAGEPULLSECRET_SP_CLIENT_SECRET}"
fi

echo $(date -u) "[INFO] Helm install of the Services (timedout in 10 min) ..."
linux-amd64/helm install ${HELM_CHART_RELEASE_NAME} ${HELM_CHART_PATH} \
  --wait \
  --timeout 600s \
  --set "${HELM_CHART_SET_PARAMETERS}"

echo $(date -u) "[INFO] Sleeping to make sure pods get started .."
sleep 60s

for _SERVICE in $KUBECTL_CHECK_SERVICES; do
   echo -n $(date -u) "[INFO] Checking Pods - ${_SERVICE}: "
   _COUNT=`./kubectl wait --for=condition=ready pod -l ${KUBECTL_CHECK_SERVICES_SELECTOR_LABEL}=${_SERVICE} --timeout=60s| grep met | wc -l`
   if (( $_COUNT >= 1 )) 
   then
      echo "[UP]"
   else
      echo "[DOWN]"
      ./kubectl get pods
      ./kubectl get events
   fi
done

_INDEX=0
for _SERVICE in $KUBECTL_PORT_FORWARD_SERVICES; do
   echo $(date -u) "[INFO] Forwarding Service - ${_SERVICE} to http://localhost:808${_INDEX}"
   ./kubectl port-forward service/${_SERVICE} 808${_INDEX}:80 &
   let _INDEX=${_INDEX}+1
done

echo $(date -u) "[INFO] Pod Status"
./kubectl get pods