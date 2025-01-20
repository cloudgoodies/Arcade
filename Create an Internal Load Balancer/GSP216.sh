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

# Array of color codes excluding black and white
TEXT_COLORS=("$GREEN" "$CYAN" "$BLUE" "$MAGENTA" "$YELLOW" "$RED")
BG_COLORS=("$BG_GREEN" "$BG_BLUE" "$BG_CYAN" "$BG_MAGENTA" "$BG_YELLOW" "$BG_RED")

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

# Function to change the zone automatically
change_zone_automatically() {
    if [[ -z "$ZONE_1" ]]; then
        echo "${RED}Could not retrieve the current zone. Exiting.${RESET}"
        return 1
    fi

    echo "${CYAN}Current Zone (ZONE_1): ${BOLD}${ZONE_1}${RESET}"

    zone_prefix=${ZONE_1::-1}
    last_char=${ZONE_1: -1}
    valid_chars=("b" "c" "d")

    new_char=$last_char
    for char in "${valid_chars[@]}"; do
        if [[ $char != "$last_char" ]]; then
            new_char=$char
            break
        fi
    done

    ZONE_2="${zone_prefix}${new_char}"
    export ZONE_2
    echo "${YELLOW}New Zone (ZONE_2) is now set to: ${BOLD}${ZONE_2}${RESET}"
}

#----------------------------------------------------start--------------------------------------------------#

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

# Step 1: Retrieve default zone and region
echo "${BLUE}Retrieving default zone and region.${RESET}"
export ZONE_1=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Create firewall rule to allow HTTP traffic
echo "${GREEN}Creating firewall rule to allow HTTP traffic.${RESET}"
gcloud compute firewall-rules create app-allow-http \
    --direction=INGRESS \
    --priority=1000 \
    --network=my-internal-app \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=10.10.0.0/16 \
    --target-tags=lb-backend

# Step 3: Create firewall rule to allow health checks
echo "${CYAN}Creating firewall rule to allow health checks.${RESET}"
gcloud compute firewall-rules create app-allow-health-check \
    --direction=INGRESS \
    --priority=1000 \
    --network=my-internal-app \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=lb-backend

# Step 4: Create instance template for subnet-a
echo "${MAGENTA}Creating instance template for subnet-a.${RESET}"
gcloud compute instance-templates create instance-template-1 \
    --machine-type e2-micro \
    --network my-internal-app \
    --subnet subnet-a \
    --tags lb-backend \
    --metadata startup-script-url=gs://cloud-training/gcpnet/ilb/startup.sh \
    --region="$REGION"

# Step 5: Create instance template for subnet-b
echo "${YELLOW}Creating instance template for subnet-b.${RESET}"
gcloud compute instance-templates create instance-template-2 \
    --machine-type e2-micro \
    --network my-internal-app \
    --subnet subnet-b \
    --tags lb-backend \
    --metadata startup-script-url=gs://cloud-training/gcpnet/ilb/startup.sh \
    --region="$REGION"

# Step 6: Determine and set the secondary zone
echo "${RED}Determining and setting the secondary zone.${RESET}"
change_zone_automatically

# Step 7: Create managed instance group 1
echo "${BLUE}Creating managed instance group 1.${RESET}"
gcloud beta compute instance-groups managed create instance-group-1 \
    --project="$DEVSHELL_PROJECT_ID" \
    --base-instance-name=instance-group-1 \
    --size=1 \
    --template=instance-template-1 \
    --zone="$ZONE_1" \
    --list-managed-instances-results=PAGELESS \
    --no-force-update-on-repair

# Step 8: Set autoscaling for instance group 1
echo "${GREEN}Setting autoscaling for instance group 1.${RESET}"
gcloud beta compute instance-groups managed set-autoscaling instance-group-1 \
    --project="$DEVSHELL_PROJECT_ID" \
    --zone="$ZONE_1" \
    --cool-down-period=45 \
    --max-num-replicas=5 \
    --min-num-replicas=1 \
    --mode=on \
    --target-cpu-utilization=0.8

# Step 9: Create managed instance group 2
echo "${MAGENTA}Creating managed instance group 2.${RESET}"
gcloud beta compute instance-groups managed create instance-group-2 \
    --project="$DEVSHELL_PROJECT_ID" \
    --base-instance-name=instance-group-2 \
    --size=1 \
    --template=instance-template-2 \
    --zone="$ZONE_2" \
    --list-managed-instances-results=PAGELESS \
    --no-force-update-on-repair

# Step 10: Set autoscaling for instance group 2
echo "${CYAN}Setting autoscaling for instance group 2.${RESET}"
gcloud beta compute instance-groups managed set-autoscaling instance-group-2 \
    --project="$DEVSHELL_PROJECT_ID" \
    --zone="$ZONE_2" \
    --cool-down-period=45 \
    --max-num-replicas=5 \
    --min-num-replicas=1 \
    --mode=on \
    --target-cpu-utilization=0.8

# Step 11: Create utility VM
echo "${YELLOW}Creating utility VM.${RESET}"
gcloud compute instances create utility-vm \
    --zone="$ZONE_1" \
    --machine-type e2-micro \
    --network my-internal-app \
    --subnet subnet-a \
    --private-network-ip 10.10.20.50

# Remove unnecessary files
function remove_files() {
    for file in *; do
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]] && [[ -f "$file" ]]; then
            rm "$file"
            echo "${MAGENTA}File removed: ${BOLD}$file${RESET}"
        fi
    done
}

remove_files
