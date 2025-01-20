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
TEXT_COLORS=("$RED" "$GREEN" "$YELLOW" "$BLUE" "$MAGENTA" "$CYAN")
BG_COLORS=("$BG_RED" "$BG_GREEN" "$BG_YELLOW" "$BG_BLUE" "$BG_MAGENTA" "$BG_CYAN")

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[RANDOM % ${#BG_COLORS[@]}]}

# Function to change zone automatically
change_zone_automatically() {
    echo "${CYAN}${BOLD}Determining the secondary zone automatically...${RESET}"

    if [[ -z "$ZONE_1" ]]; then
        echo "${RED}Could not retrieve the current zone. Exiting.${RESET}"
        return 1
    fi

    echo "${GREEN}Current Zone (ZONE_1): $ZONE_1${RESET}"

    # Extract the zone prefix (everything except the last character)
    zone_prefix=${ZONE_1::-1}
    last_char=${ZONE_1: -1}

    # Valid zone characters
    valid_chars=("b" "c" "d")

    # Determine the next valid character
    new_char=""
    for char in "${valid_chars[@]}"; do
        if [[ "$char" != "$last_char" ]]; then
            new_char=$char
            break
        fi
    done

    if [[ -z "$new_char" ]]; then
        echo "${RED}Error: Unable to determine the new zone character.${RESET}"
        return 1
    fi

    # Construct the new zone
    ZONE_2="${zone_prefix}${new_char}"
    export ZONE_2
    echo "${YELLOW}New Zone (ZONE_2): $ZONE_2${RESET}"
}

#----------------------------------------------------Start--------------------------------------------------#

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

# Step 1: Retrieve default zone and region
echo "${CYAN}${BOLD}Retrieving default zone and region.${RESET}"
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
echo "${RED}${BOLD}Creating firewall rule to allow health checks.${RESET}"
gcloud compute firewall-rules create app-allow-health-check \
    --direction=INGRESS \
    --priority=1000 \
    --network=my-internal-app \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=lb-backend

# Call the function to determine the secondary zone
change_zone_automatically

#----------------------------------------------------Remove Files--------------------------------------------------#

echo "${BLUE}${BOLD}Cleaning up unnecessary files...${RESET}"

remove_files() {
    for file in *; do
        # Check if the file matches the patterns and is a regular file
        if [[ "$file" =~ ^(gsp|arc|shell).* && -f "$file" ]]; then
            rm "$file"
            echo "${GREEN}File removed: $file${RESET}"
        fi
    done
}

# Call the remove_files function
remove_files

# Display a random congratulatory message
function random_congrats() {
    MESSAGES=(
        "${GREEN}Congratulations on completing the lab! Great job!${RESET}"
        "${CYAN}Well done! Your efforts paid off!${RESET}"
        "${YELLOW}Amazing work! Keep it up!${RESET}"
        "${MAGENTA}Fantastic! You’ve mastered this!${RESET}"
        "${RED}Impressive! Your dedication is admirable!${RESET}"
    )

    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}${RESET}"
}

random_congrats
