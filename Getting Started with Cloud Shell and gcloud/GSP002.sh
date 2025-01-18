#!/bin/bash

# Add colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================="
echo -e "       Google Cloud Instance Setup      "
echo -e "=======================================${NC}\n"

# Prompt for zone with cyan color
echo -e "${CYAN}Please enter the zone where you want to create the instance:${NC}"
read -p "ENTER ZONE: " ZONE

echo -e "\n${GREEN}Creating a compute instance named 'gcelab2' in zone '$ZONE'...${NC}"
gcloud compute instances create gcelab2 --machine-type e2-medium --zone $ZONE

echo -e "\n${GREEN}Adding tags 'http-server' and 'https-server' to the instance...${NC}"
gcloud compute instances add-tags gcelab2 --zone $ZONE --tags http-server,https-server

echo -e "\n${GREEN}Creating a firewall rule to allow HTTP traffic on port 80...${NC}"
gcloud compute firewall-rules create default-allow-http \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server

echo -e "\n${GREEN}Congratulations Lab is Completed!${NC}"
echo -e "${BLUE}=======================================${NC}"
