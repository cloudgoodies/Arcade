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
TEXT_COLORS=($CYAN $MAGENTA $GREEN $YELLOW $BLUE $RED)
BG_COLORS=($BG_CYAN $BG_MAGENTA $BG_GREEN $BG_YELLOW $BG_BLUE $BG_RED)

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

# Function to change zone automatically
change_zone_automatically() {
    if [[ -z "$ZONE_1" ]]; then
        echo "${RED}${BOLD}Could not retrieve the current zone. Exiting.${RESET}"
        return 1
    fi

    echo "${YELLOW}${BOLD}Current Zone (ZONE_1): $ZONE_1${RESET}"

    # Extract zone prefix and last character
    zone_prefix=${ZONE_1::-1}
    last_char=${ZONE_1: -1}

    # List of valid zone characters
    valid_chars=("b" "c" "d")

    # Find the next valid character
    new_char=$last_char
    for char in "${valid_chars[@]}"; do
        if [[ $char != "$last_char" ]]; then
            new_char=$char
            break
        fi
    done

    # Construct new zone
    ZONE_2="${zone_prefix}${new_char}"
    export ZONE_2
    echo "${GREEN}${BOLD}New Zone (ZONE_2) is now set to: $ZONE_2${RESET}"
}

#---------------------------------------------------- Start --------------------------------------------------#

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

# Step 1: Retrieve default zone and region
echo "${BLUE}${BOLD}Retrieving default zone and region.${RESET}"
export ZONE_1=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Create firewall rule to allow HTTP traffic
echo "${MAGENTA}${BOLD}Creating firewall rule to allow HTTP traffic.${RESET}"
gcloud compute firewall-rules create app-allow-http \
    --direction=INGRESS \
    --priority=1000 \
    --network=my-internal-app \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=10.10.0.0/16 \
    --target-tags=lb-backend

# Step 3: Create firewall rule to allow health checks
echo "${CYAN}${BOLD}Creating firewall rule to allow health checks.${RESET}"
gcloud compute firewall-rules create app-allow-health-check \
    --direction=INGRESS \
    --priority=1000 \
    --network=my-internal-app \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=lb-backend

# Step 4: Create instance templates
echo "${YELLOW}${BOLD}Creating instance templates.${RESET}"
gcloud compute instance-templates create instance-template-1 \
    --machine-type e2-micro \
    --network my-internal-app \
    --subnet subnet-a \
    --tags lb-backend \
    --metadata startup-script-url=gs://cloud-training/gcpnet/ilb/startup.sh \
    --region=$REGION

gcloud compute instance-templates create instance-template-2 \
    --machine-type e2-micro \
    --network my-internal-app \
    --subnet subnet-b \
    --tags lb-backend \
    --metadata startup-script-url=gs://cloud-training/gcpnet/ilb/startup.sh \
    --region=$REGION

# Step 5: Determine and set the secondary zone
echo "${MAGENTA}${BOLD}Determining and setting the secondary zone.${RESET}"
change_zone_automatically

# Other steps (e.g., creating instance groups, autoscaling, utility VM) follow similar logic...
# Replace all messages with new color schemes as shown above

# Function to remove files
remove_files() {
    echo "${YELLOW}${BOLD}Cleaning up files...${RESET}"
    for file in *; do
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            if [[ -f "$file" ]]; then
                rm "$file"
                echo "${GREEN}File removed: $file${RESET}"
            fi
        fi
    done
}

remove_files
echo "${BG_GREEN}${WHITE}${BOLD}Congratulations! You have successfully completed the lab!${RESET}"
