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

# Array of colors
TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

# Function to handle progress prompt
check_progress() {
    while true; do
        echo -n "${BOLD}${YELLOW}Have you created sink AuditLogsExport? (Y/N): ${RESET}"
        read -r user_input
        case "$user_input" in
            [Yy]*) 
                echo "${BOLD}${CYAN}Great! Proceeding to the next steps...${RESET}"
                break
                ;;
            [Nn]*) 
                echo "${BOLD}${RED}Please create sink named AuditLogsExport and then press Y to continue.${RESET}"
                ;;
            *) 
                echo "${BOLD}${MAGENTA}Invalid input. Please enter Y or N.${RESET}"
                ;;
        esac
    done
}

# Function to handle errors
exit_on_failure() {
    if [ $? -ne 0 ]; then
        echo "${BOLD}${RED}Error occurred. Exiting.${RESET}"
        exit 1
    fi
}

# Start execution
echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

# Step 1: Setting the default zone
echo "${CYAN}${BOLD}Setting the default zone...${RESET}"
ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
exit_on_failure

# Step 2: Exporting current IAM policy
echo "${MAGENTA}${BOLD}Exporting the current IAM policy to policy.json...${RESET}"
gcloud projects get-iam-policy "$DEVSHELL_PROJECT_ID" --format=json > policy.json
exit_on_failure

# Step 3: Updating IAM policy for audit logging
echo "${BLUE}${BOLD}Updating IAM policy for audit logging...${RESET}"
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
exit_on_failure

# Step 4: Applying the updated IAM policy
echo "${GREEN}${BOLD}Applying the updated IAM policy...${RESET}"
gcloud projects set-iam-policy "$DEVSHELL_PROJECT_ID" ./updated_policy.json
exit_on_failure

# Step 5: Creating BigQuery dataset
echo "${YELLOW}${BOLD}Creating BigQuery dataset 'auditlogs_dataset'...${RESET}"
bq --location=US mk --dataset "$DEVSHELL_PROJECT_ID:auditlogs_dataset"
exit_on_failure

# Prompt user to proceed
check_progress

# Step 6: Setting up Cloud Storage bucket
echo "${BLUE}${BOLD}Setting up Cloud Storage bucket and uploading a sample file...${RESET}"
gsutil mb gs://"$DEVSHELL_PROJECT_ID"
echo "this is a sample file" > sample.txt
gsutil cp sample.txt gs://"$DEVSHELL_PROJECT_ID"
exit_on_failure

# Step 7: Creating VPC network and VM instance
echo "${MAGENTA}${BOLD}Creating VPC network and VM instance...${RESET}"
gcloud compute networks create mynetwork --subnet-mode=auto
gcloud compute instances create default-us-vm --machine-type=e2-micro --zone="$ZONE" --network=mynetwork
exit_on_failure

# Step 8: Deleting bucket and capturing logs
echo "${GREEN}${BOLD}Deleting bucket and capturing logs...${RESET}"
gsutil rm -r gs://"$DEVSHELL_PROJECT_ID"
gcloud logging read "logName=projects/$DEVSHELL_PROJECT_ID/logs/cloudaudit.googleapis.com%2Factivity AND protoPayload.serviceName=storage.googleapis.com AND protoPayload.methodName=storage.buckets.delete"
exit_on_failure

# Step 9: Creating another bucket and testing
echo "${YELLOW}${BOLD}Creating another bucket and testing...${RESET}"
gsutil mb gs://"$DEVSHELL_PROJECT_ID-test"
echo "this is another sample file" > sample2.txt
gsutil cp sample2.txt gs://"$DEVSHELL_PROJECT_ID-test"
exit_on_failure

# Step 10: Deleting VM instance
echo "${RED}${BOLD}Deleting VM instance...${RESET}"
gcloud compute instances delete default-us-vm --zone="$ZONE" --delete-disks=all --quiet
exit_on_failure

# Step 11: Querying BigQuery for logs
echo "${CYAN}${BOLD}Querying BigQuery for logs...${RESET}"
bq query --nouse_legacy_sql --project_id="$DEVSHELL_PROJECT_ID" '
SELECT
  timestamp,
  resource.labels.instance_id,
  protopayload_auditlog.authenticationInfo.principalEmail,
  protopayload_auditlog.resourceName,
  protopayload_auditlog.methodName
FROM
  `auditlogs_dataset.cloudaudit_googleapis_com_activity_*`
WHERE
  PARSE_DATE("%Y%m%d", _TABLE_SUFFIX) BETWEEN
  DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) AND
  CURRENT_DATE()
  AND protopayload_auditlog.methodName = "v1.compute.instances.delete"
LIMIT 1000'
exit_on_failure

# Step 12: Display a random congratulatory message
echo "${BOLD}${GREEN}Congratulations! You have successfully completed the lab.${RESET}"

# Clean up files
echo "${CYAN}${BOLD}Cleaning up generated files...${RESET}"
remove_files() {
    for file in *; do
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            if [[ -f "$file" ]]; then
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

remove_files
