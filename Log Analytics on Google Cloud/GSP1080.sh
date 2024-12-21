#!/bin/bash
# Define color variables

CLR_BLACK=tput setaf 0
CLR_RED=tput setaf 1
CLR_GREEN=tput setaf 2
CLR_YELLOW=tput setaf 3
CLR_BLUE=tput setaf 4
CLR_MAGENTA=tput setaf 5
CLR_CYAN=tput setaf 6
CLR_WHITE=tput setaf 7

CLR_BG_BLACK=tput setab 0
CLR_BG_RED=tput setab 1
CLR_BG_GREEN=tput setab 2
CLR_BG_YELLOW=tput setab 3
CLR_BG_BLUE=tput setab 4
CLR_BG_MAGENTA=tput setab 5
CLR_BG_CYAN=tput setab 6
CLR_BG_WHITE=tput setab 7

CLR_BOLD=tput bold
CLR_RESET=tput sgr0

#----------------------------------------------------start--------------------------------------------------#

echo "${CLR_BG_MAGENTA}${CLR_BOLD}Starting Execution${CLR_RESET}"

export CLUSTER_REGION=$(gcloud container clusters list --format='value(LOCATION)')

gcloud container clusters get-credentials day2-ops --region "$CLUSTER_REGION"

git clone https://github.com/GoogleCloudPlatform/microservices-demo.git

cd microservices-demo || exit 1

kubectl apply -f release/kubernetes-manifests.yaml

sleep 60

export SERVICE_EXTERNAL_IP=$(kubectl get service frontend-external -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
echo "$SERVICE_EXTERNAL_IP"

curl -o /dev/null -s -w "%{http_code}\n"  "http://${SERVICE_EXTERNAL_IP}"

gcloud logging buckets update _Default \
    --location=global \
    --enable-analytics

gcloud logging sinks create day2ops-sink \
    "logging.googleapis.com/projects/$DEVSHELL_PROJECT_ID/locations/global/buckets/day2ops-log" \
    --log-filter='resource.type="k8s_container"' \
    --include-children \
    --format='json'

echo "${CLR_CYAN}${CLR_BOLD}Click here: ${CLR_RESET}${CLR_BLUE}${CLR_BOLD}https://console.cloud.google.com/logs/storage/bucket?project=$DEVSHELL_PROJECT_ID${CLR_RESET}"
echo "${CLR_YELLOW}Congratulations you have completed this lab."
