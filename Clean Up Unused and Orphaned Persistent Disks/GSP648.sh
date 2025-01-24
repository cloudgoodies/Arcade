#!/bin/bash

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Listing authenticated gcloud accounts...${NC}"
gcloud auth list

echo -e "${BLUE}Setting zone and region variables...${NC}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo -e "${BLUE}Enabling Cloud Scheduler API...${NC}"
gcloud services enable cloudscheduler.googleapis.com && \
echo -e "${GREEN}Cloud Scheduler API enabled successfully!${NC}"

echo -e "${BLUE}Copying resources and setting up environment...${NC}"
gsutil cp -r gs://spls/gsp648 . && cd gsp648

export PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null)
WORKDIR=$(pwd)
gcloud config set compute/region $REGION
export REGION=$REGION
export ZONE=$ZONE

cd $WORKDIR/unattached-pd

export ORPHANED_DISK=orphaned-disk
export UNUSED_DISK=unused-disk

echo -e "${BLUE}Creating disks...${NC}"
gcloud compute disks create $ORPHANED_DISK --project=$PROJECT_ID --type=pd-standard --size=500GB --zone=$ZONE && \
echo -e "${GREEN}Disk $ORPHANED_DISK created successfully!${NC}"

gcloud compute disks create $UNUSED_DISK --project=$PROJECT_ID --type=pd-standard --size=500GB --zone=$ZONE && \
echo -e "${GREEN}Disk $UNUSED_DISK created successfully!${NC}"

echo -e "${BLUE}Listing disks...${NC}"
gcloud compute disks list

echo -e "${BLUE}Creating instance and attaching orphaned disk...${NC}"
gcloud compute instances create disk-instance \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --disk=name=$ORPHANED_DISK,device-name=$ORPHANED_DISK,mode=rw,boot=no && \
echo -e "${GREEN}Instance disk-instance created and disk $ORPHANED_DISK attached!${NC}"

echo -e "${BLUE}Describing orphaned disk...${NC}"
gcloud compute disks describe $ORPHANED_DISK --zone=$ZONE --format=json | jq

echo -e "${BLUE}Detaching orphaned disk...${NC}"
gcloud compute instances detach-disk disk-instance --device-name=$ORPHANED_DISK --zone=$ZONE && \
echo -e "${GREEN}Disk $ORPHANED_DISK detached successfully!${NC}"

echo -e "${BLUE}Describing orphaned disk again...${NC}"
gcloud compute disks describe $ORPHANED_DISK --zone=$ZONE --format=json | jq

echo -e "${BLUE}Deploying Cloud Function...${NC}"
gcloud functions deploy delete_unattached_pds --gen2 --trigger-http --runtime=python39 --region=$REGION && \
echo -e "${GREEN}Cloud Function deployed successfully!${NC}"

export FUNCTION_URL=$(gcloud functions describe delete_unattached_pds --format=json --region $REGION | jq -r '.url')

echo -e "${BLUE}Creating App Engine app...${NC}"
gcloud app create --region=$REGION && \
echo -e "${GREEN}App Engine app created successfully!${NC}"

echo -e "${BLUE}Deploying App Engine app...${NC}"
gcloud app deploy && \
echo -e "${GREEN}App Engine app deployed successfully!${NC}"

echo -e "${BLUE}Creating Cloud Scheduler job...${NC}"
gcloud scheduler jobs create http unattached-pd-job \
  --schedule="* 2 * * *" \
  --uri=$FUNCTION_URL \
  --location=$REGION && \
echo -e "${GREEN}Cloud Scheduler job created successfully!${NC}"

# Retry loop for running the function
running_function() {
  gcloud scheduler jobs run unattached-pd-job --location="$REGION"
}

running_success=false

while [ "$running_success" = false ]; do
  if running_function; then
    echo -e "${GREEN}Function started running successfully!${NC}"
    running_success=true
  else
    echo -e "${RED}Running failed. Retrying in 10 seconds...${NC}"
    echo -e "${YELLOW}Please subscribe to TechCPS [https://www.youtube.com/@techcps].${NC}"
    sleep 10
  fi
done

echo -e "${BLUE}Listing compute snapshots...${NC}"
gcloud compute snapshots list

echo -e "${BLUE}Listing compute disks...${NC}"
gcloud compute disks list

echo -e "${BLUE}Creating a new orphaned disk...${NC}"
gcloud compute disks create $ORPHANED_DISK --project=$PROJECT_ID --type=pd-standard --size=500GB --zone=$ZONE && \
echo -e "${GREEN}New disk $ORPHANED_DISK created successfully!${NC}"

echo -e "${BLUE}Attaching orphaned disk to disk-instance...${NC}"
gcloud compute instances attach-disk disk-instance --device-name=$ORPHANED_DISK --disk=$ORPHANED_DISK --zone=$ZONE && \
echo -e "${GREEN}Disk $ORPHANED_DISK attached successfully! Congratulations! 🎉${NC}"
