#!/bin/bash
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Execution${NC}"

gcloud auth list
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export PROJECT_ID=$(gcloud config get-value project)
gcloud config set compute/zone "$ZONE"
gcloud compute networks create workspace-vpc --subnet-mode=custom
gcloud compute networks create private-vpc --subnet-mode=custom
gcloud compute networks peerings create workspace-to-private --network=workspace-vpc --peer-network=private-vpc --auto-create-routes
gcloud compute networks peerings create private-to-workspace --network=private-vpc --peer-network=workspace-vpc --auto-create-routes
gcloud compute ssh workspace-vm --project="$PROJECT_ID" --zone="$ZONE"

echo "${GREEN}${BOLD}Congratulations${RESET} ${GREEN}${BOLD}for${RESET} ${GREEN}${BOLD}Completing the Lab !!!${RESET}"
