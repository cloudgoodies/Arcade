#!/bin/bash

clear

# Define color variables
BLACK=tput setaf 0
RED=tput setaf 1
GREEN=tput setaf 2
YELLOW=tput setaf 3
BLUE=tput setaf 4
MAGENTA=tput setaf 5
CYAN=tput setaf 6
WHITE=tput setaf 7

BG_BLACK=tput setab 0
BG_RED=tput setab 1
BG_GREEN=tput setab 2
BG_YELLOW=tput setab 3
BG_BLUE=tput setab 4
BG_MAGENTA=tput setab 5
BG_CYAN=tput setab 6
BG_WHITE=tput setab 7

BOLD=tput bold
RESET=tput sgr0

# Array of color codes excluding black and white
TXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BACKGROUND_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

# Pick random colors
RANDOM_TXT_COLOR=${TXT_COLORS[$RANDOM % ${#TXT_COLORS[@]}]}
RANDOM_BACKGROUND_COLOR=${BACKGROUND_COLORS[$RANDOM % ${#BACKGROUND_COLORS[@]}]}

# Function to fetch the table ID and format it with the desired output pattern
retrieve_table_id() {
    export current_project_id=$DEVSHELL_PROJECT_ID
    export current_dataset_id="project_logs"
    export output_string=""

    while true; do
        # Fetch the table ID from BigQuery
        export fetched_table_id=$(bq ls --project_id "$current_project_id" --dataset_id "$current_dataset_id" --format=json \
            | jq -r '.[0].tableReference.tableId')

        # Check if fetched_table_id is empty
        if [[ -n "$fetched_table_id" ]]; then
            # Format the output as desired
            output_string="$current_project_id.$current_dataset_id.${fetched_table_id}"
            break
        fi

        echo "Waiting for table to be available..."
        sleep 5
    done
}

#----------------------------------------------------start--------------------------------------------------#

echo "${RANDOM_BACKGROUND_COLOR}${RANDOM_TXT_COLOR}${BOLD}Starting Execution${RESET}"

# Step 1: Set the default zone from project metadata
echo -e "${GREEN}${BOLD}Setting the default zone from project metadata...${RESET}"
export DEFAULT_ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Step 2: Fetching Project ID and Project Number
echo -e "${YELLOW}${BOLD}Fetching Project ID and Project Number...${RESET}"
export CURRENT_PROJECT_ID=$(gcloud config get-value project)
export CURRENT_PROJECT_NUMBER=$(gcloud projects describe ${CURRENT_PROJECT_ID} \
    --format="value(projectNumber)")

mkdir stackdriver-lab
cd stackdriver-lab

# Step 3: Download necessary files
echo -e "${MAGENTA}${BOLD}Downloading necessary files for the lab...${RESET}"
FILES_LIST=( 
    "activity.sh"
    "apache2.conf"
    "basic-ingress.yaml"
    "gke.sh"
    "linux_startup.sh"
    "pubsub.sh"
    "setup.sh"
    "sql.sh"
    "windows_startup.ps1"
)

FILE_BASE_URL="https://github.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/raw/refs/heads/main/Configuring%20and%20Using%20Cloud%20Logging%20and%20Cloud%20Monitoring/stackdriver-lab"

for single_file in "${FILES_LIST[@]}"; do
    curl -LO "${FILE_BASE_URL}/${single_file}"
done

# Step 4: Update setup.sh with the current zone
echo -e "${CYAN}${BOLD}Updating 'setup.sh' with the current zone...${RESET}"
sed -i "s/us-west1-b/$DEFAULT_ZONE/g" setup.sh

# Step 5: Make necessary scripts executable and run setup
echo -e "${RED}${BOLD}Making scripts executable and running 'setup.sh'...${RESET}"
chmod +x *.sh
./setup.sh

# Step 6: Create a BigQuery dataset for logs
echo -e "${GREEN}${BOLD}Creating a BigQuery dataset named 'project_logs'...${RESET}"
bq mk project_logs

# Step 7: Create logging sinks for VM and Load Balancer logs
echo -e "${YELLOW}${BOLD}Creating logging sinks for VM and Load Balancer logs...${RESET}"
gcloud logging sinks create vm_logs \
    bigquery.googleapis.com/projects/$DEVSHELL_PROJECT_ID/datasets/project_logs \
    --log-filter='resource.type="gce_instance"'

gcloud logging sinks create load_bal_logs \
    bigquery.googleapis.com/projects/$DEVSHELL_PROJECT_ID/datasets/project_logs \
    --log-filter="resource.type=\"http_load_balancer\""
