#!/bin/bash
YELLOW='\033[0;33m'
NC='\033[0m' 

gcloud auth list
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export PROJECT_ID=$(gcloud config get-value project)
gcloud config set compute/zone "$ZONE"
gcloud compute instances stop lab-vm --zone="$ZONE"
sleep 15
gcloud compute instances set-machine-type lab-vm --machine-type e2-medium --zone="$ZONE"
sleep 16
gcloud compute instances start lab-vm  --zone="$ZONE"
