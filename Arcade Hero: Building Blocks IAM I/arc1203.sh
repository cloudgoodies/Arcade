#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Fetching default region and zone...${NC}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

echo -e "${GREEN}Region: $REGION${NC}"
echo -e "${GREEN}Zone: $ZONE${NC}"

PROJECT_ID=$(gcloud config get-value project)

echo -e "${YELLOW}Fetching users with Viewer role...${NC}"
users=($(gcloud projects get-iam-policy $PROJECT_ID --format=json | jq -r '.bindings[] | select(.role=="roles/viewer") | .members[]' | sed 's/user://g'))

# Assign each user to a separate variable dynamically
for i in "${!users[@]}"; do
    eval "USER$((i+1))=${users[i]}"
done

# Print all stored users
echo -e "${BLUE}Users with Viewer role:${NC}"
for i in "${!users[@]}"; do
    eval "echo -e ${GREEN}User$((i+1)): \$USER$((i+1))${NC}"
done

echo -e "${YELLOW}Assigning Editor role to User3...${NC}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="user:$USER3" \
    --role="roles/editor"

sleep 20

echo -e "${YELLOW}Assigning Compute Admin role to User1...${NC}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="user:$USER1" \
    --role="roles/compute.admin"

echo -e "${GREEN}IAM roles updated successfully!${NC}"

echo -e "${GREEN}Congratulations for completing the lab!${NC}"
