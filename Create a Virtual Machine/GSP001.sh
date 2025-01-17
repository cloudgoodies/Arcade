#!/bin/bash
# Define color variables
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

BOLD=$(tput bold)
RESET=$(tput sgr0)

#----------------------------------------------------start--------------------------------------------------#

echo "${BG_BLUE}${BOLD}=== Starting Execution ===${RESET}"

# Retrieve project ID and number
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format="value(projectNumber)")

# Create the first VM instance
echo "${GREEN}Creating VM instance 'gcelab'...${RESET}"
gcloud compute instances create gcelab \
    --project="${DEVSHELL_PROJECT_ID}" \
    --zone="${ZONE}" \
    --machine-type=e2-medium \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --metadata=enable-oslogin=true \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append \
    --tags=http-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=gcelab,image=projects/debian-cloud/global/images/debian-11-bullseye-v20241009,mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any

# Create the second VM instance
echo "${YELLOW}Creating VM instance 'gcelab2'...${RESET}"
gcloud compute instances create gcelab2 \
    --machine-type=e2-medium \
    --zone="${ZONE}"

# SSH into the first VM instance and install NGINX
echo "${CYAN}Connecting to 'gcelab' and setting up NGINX...${RESET}"
gcloud compute ssh --zone "${ZONE}" "gcelab" --project "${DEVSHELL_PROJECT_ID}" --quiet --command \
    "sudo apt-get update && sudo apt-get install -y nginx && ps auwx | grep nginx"

# Create a firewall rule to allow HTTP traffic
echo "${MAGENTA}Creating firewall rule to allow HTTP traffic...${RESET}"
gcloud compute firewall-rules create allow-http \
    --network=default \
    --allow=tcp:80 \
    --target-tags=http-server

# Completion message
echo "${BG_GREEN}${BOLD}=== Congratulations For Completing The Lab !!! ===${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
