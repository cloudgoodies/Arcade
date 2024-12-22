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

# Function to generate a random color combination
function random_color_combination() {
    local text_color=${TEXT_COLORS[RANDOM % ${#TEXT_COLORS[@]}]}
    local bg_color=${BG_COLORS[RANDOM % ${#BG_COLORS[@]}]}
    echo "$bg_color$text_color$BOLD"
}

# Function to check user progress
function prompt_user_progress() {
    local prompt_message="${BOLD}${YELLOW}Have you created the sink 'AuditLogsExport'? (Y/N): ${RESET}"
    local invalid_input_message="${BOLD}${MAGENTA}Invalid input. Please enter Y or N.${RESET}"
    local incomplete_message="${BOLD}${RED}Please create the sink and then press Y to continue.${RESET}"
    local success_message="${BOLD}${CYAN}Great! Proceeding to the next steps...${RESET}"

    while true; do
        echo
        echo -n "$prompt_message"
        read -r user_input
        case "$user_input" in
            [Yy])
                echo
                echo "$success_message"
                echo
                break
                ;;
            [Nn])
                echo
                echo "$incomplete_message"
                ;;
            *)
                echo
                echo "$invalid_input_message"
                ;;
        esac
    done
}

# Display a random start message
echo "$(random_color_combination)Starting Execution${RESET}"

# Step 1: Setting default zone
echo -e "${CYAN}${BOLD}Setting the default zone...${RESET}"
ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Step 2: Export IAM policy
echo -e "${MAGENTA}${BOLD}Exporting IAM policy to policy.json...${RESET}"
gcloud projects get-iam-policy "$DEVSHELL_PROJECT_ID" --format=json > policy.json

# Step 3: Update IAM policy
echo -e "${BLUE}${BOLD}Updating IAM policy to enable audit logging...${RESET}"
jq '.auditConfigs = [
  {
    "service": "allServices",
    "auditLogConfigs": [
      { "logType": "ADMIN_READ" },
      { "logType": "DATA_READ" },
      { "logType": "DATA_WRITE" }
    ]
  }
] | .' policy.json > updated_policy.json

# Step 4: Apply updated IAM policy
echo -e "${GREEN}${BOLD}Applying the updated IAM policy...${RESET}"
gcloud projects set-iam-policy "$DEVSHELL_PROJECT_ID" updated_policy.json

# Step 5: Create BigQuery dataset
echo -e "${YELLOW}${BOLD}Creating a BigQuery dataset named 'auditlogs_dataset'...${RESET}"
bq --location=US mk --dataset "$DEVSHELL_PROJECT_ID:auditlogs_dataset"

# Step 6: Display Logs Explorer instructions
echo -e "${RED}${BOLD}Visit the Logs Explorer in GCP Console...${RESET}"
echo
echo "Go to: https://console.cloud.google.com/logs/query"
echo "Copy this filter: logName = (\"projects/$DEVSHELL_PROJECT_ID/logs/cloudaudit.googleapis.com%2Factivity\")"
echo "SINK NAME: AuditLogsExport"
echo

# Prompt user to check progress
prompt_user_progress

# Step 7: Cloud Storage bucket setup
echo -e "${BLUE}${BOLD}Creating Cloud Storage bucket and uploading sample file...${RESET}"
gsutil mb gs://"$DEVSHELL_PROJECT_ID"
echo "this is a sample file" > sample.txt
gsutil cp sample.txt gs://"$DEVSHELL_PROJECT_ID"

# Step 8: Create VPC network and VM instance
echo -e "${MAGENTA}${BOLD}Creating a VPC network and VM instance...${RESET}"
gcloud compute networks create mynetwork --subnet-mode=auto
gcloud compute instances create default-us-vm \
    --machine-type=e2-micro \
    --zone="$ZONE" --network=mynetwork

# Step 9: Delete bucket and capture logs
echo -e "${GREEN}${BOLD}Deleting bucket and capturing logs...${RESET}"
gsutil rm -r gs://"$DEVSHELL_PROJECT_ID"
gcloud logging read \
    "logName=projects/$DEVSHELL_PROJECT_ID/logs/cloudaudit.googleapis.com%2Factivity AND protoPayload.serviceName=storage.googleapis.com AND protoPayload.methodName=storage.buckets.delete"

# Step 10: Delete files matching specific patterns
function remove_files_by_pattern() {
    local patterns=("gsp*" "arc*" "shell*")
    for pattern in "${patterns[@]}"; do
        for file in $pattern; do
            if [[ -f "$file" ]]; then
                rm "$file"
                echo "Removed file: $file"
            fi
        done
    done
}

remove_files_by_pattern

# Display random congratulations
function display_random_congratulations() {
    local messages=(
        "${GREEN}Congratulations! You’ve completed the lab!${RESET}"
        "${CYAN}Well done! Keep up the great work!${RESET}"
        "${YELLOW}Fantastic effort! You’ve succeeded!${RESET}"
        "${BLUE}Amazing job! You’re on a roll!${RESET}"
    )
    echo -e "${BOLD}${messages[RANDOM % ${#messages[@]}]}"
}

display_random_congratulations
