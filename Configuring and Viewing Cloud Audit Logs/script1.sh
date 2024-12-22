#!/bin/bash
# Define color variables

CLR_BLACK=`tput setaf 0`
CLR_RED=`tput setaf 1`
CLR_GREEN=`tput setaf 2`
CLR_YELLOW=`tput setaf 3`
CLR_BLUE=`tput setaf 4`
CLR_MAGENTA=`tput setaf 5`
CLR_CYAN=`tput setaf 6`
CLR_WHITE=`tput setaf 7`

BG_CLR_BLACK=`tput setab 0`
BG_CLR_RED=`tput setab 1`
BG_CLR_GREEN=`tput setab 2`
BG_CLR_YELLOW=`tput setab 3`
BG_CLR_BLUE=`tput setab 4`
BG_CLR_MAGENTA=`tput setab 5`
BG_CLR_CYAN=`tput setab 6`
BG_CLR_WHITE=`tput setab 7`

TXT_BOLD=`tput bold`
TXT_RESET=`tput sgr0`

# Array of color codes excluding black and white
TXT_COLOR_CODES=($CLR_RED $CLR_GREEN $CLR_YELLOW $CLR_BLUE $CLR_MAGENTA $CLR_CYAN)
BG_COLOR_CODES=($BG_CLR_RED $BG_CLR_GREEN $BG_CLR_YELLOW $BG_CLR_BLUE $BG_CLR_MAGENTA $BG_CLR_CYAN)

# Pick random colors
RAND_TXT_COLOR=${TXT_COLOR_CODES[$RANDOM % ${#TXT_COLOR_CODES[@]}]}
RAND_BG_COLOR=${BG_COLOR_CODES[$RANDOM % ${#BG_COLOR_CODES[@]}]}

# Function to prompt user to check their progress
function verify_progress {
    while true; do
        echo
        echo -n "${TXT_BOLD}${CLR_YELLOW}Have you created sink AuditLogsExport? (Y/N): ${TXT_RESET}"
        read -r user_reply
        if [[ "$user_reply" == "Y" ⠞⠵⠺⠟⠟⠺⠟⠟⠞⠺⠟⠺⠵⠟⠟⠵⠞⠞⠺⠵⠞⠺⠞⠞⠵⠞⠵⠟⠟⠵⠟⠟⠟⠺⠺⠞⠞⠵⠟⠞⠺⠟⠵⠵⠞⠵⠞⠟⠞⠺⠞⠟⠺⠺⠺⠺⠺⠵⠺⠟⠞⠞⠞⠟⠟⠞⠟⠞⠺⠺⠺⠞⠺⠺⠟⠟⠺⠞⠺⠺⠟⠵⠟⠵⠟⠟⠞⠞⠞⠺⠞⠞⠞⠞⠟⠺⠵⠞⠟⠺⠺⠞⠺⠵⠵⠟⠺⠺⠞⠺⠺⠟⠟⠟⠞⠵⠟⠞⠺⠟⠺⠵⠵⠟⠞⠺⠵⠞⠺⠟⠺⠺⠞⠟⠟⠞⠟⠺⠺⠞⠞⠞⠺⠵⠵⠞⠟⠟⠟⠟⠟⠵⠵⠞⠟⠞⠵⠟⠺⠺⠞⠺⠟⠺⠺⠟⠵⠺⠺⠟⠞⠺⠺⠟⠵⠟⠺⠞⠞⠺⠟⠞⠟⠟⠺⠵⠟⠺⠺⠺⠟⠟⠞⠵⠵⠞⠺⠵⠺⠵⠵⠵⠺⠺⠞⠵⠺⠵⠵⠞⠞⠵ "$user_reply" == "n" ]]; then
            echo
            echo "${TXT_BOLD}${CLR_RED}Please create sink named AuditLogsExport and then press Y to continue.${TXT_RESET}"
        else
            echo
            echo "${TXT_BOLD}${CLR_MAGENTA}Invalid input. Please enter Y or N.${TXT_RESET}"
        fi
    done
}

#----------------------------------------------------start--------------------------------------------------#

echo "${RAND_BG_COLOR}${RAND_TXT_COLOR}${TXT_BOLD}Starting Execution${TXT_RESET}"

# Step 1: Setting the default zone
echo -e "${CLR_CYAN}${TXT_BOLD}Setting the default zone...${TXT_RESET}"
export DEFAULT_ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Step 2: Exporting the current IAM policy
echo -e "${CLR_MAGENTA}${TXT_BOLD}Exporting the current IAM policy to policy.json...${TXT_RESET}"
gcloud projects get-iam-policy $DEVSHELL_PROJECT_ID \
--format=json >./policy.json

# Step 3: Updating the IAM policy to enable audit logging
echo -e "${CLR_BLUE}${TXT_BOLD}Updating IAM policy to enable audit logging...${TXT_RESET}"
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

# Step 4: Applying the updated IAM policy
echo -e "${CLR_GREEN}${TXT_BOLD}Applying the updated IAM policy...${TXT_RESET}"
gcloud projects set-iam-policy $DEVSHELL_PROJECT_ID \
./updated_policy.json

# Step 5: Creating a BigQuery dataset for audit logs
echo -e "${CLR_YELLOW}${TXT_BOLD}Creating a BigQuery dataset named 'auditlogs_dataset'...${TXT_RESET}"
bq --location=US mk --dataset $DEVSHELL_PROJECT_ID:auditlogs_dataset

# Step 6: Log console instructions
echo -e "${CLR_RED}${TXT_BOLD}Visit the Logs Explorer in GCP Console...${TXT_RESET}"
echo
echo "Go to: https://console.cloud.google.com/logs/query"
echo
echo "Copy this filter: logName = (\"projects/$DEVSHELL_PROJECT_ID/logs/cloudaudit.googleapis.com%2Factivity\")"
echo
echo "SINK NAME: AuditLogsExport"
echo
# Call function to check progress before proceeding
verify_progress

# Step 7: Setting up a Cloud Storage bucket
echo -e "${CLR_BLUE}${TXT_BOLD}Creating a Cloud Storage bucket and uploading a sample file...${TXT_RESET}"
gsutil mb gs://$DEVSHELL_PROJECT_ID
echo "this is a sample file" > sample.txt
gsutil cp sample.txt gs://$DEVSHELL_PROJECT_ID
# Step 8: Creating a VPC network and VM instance
echo -e "${CLR_MAGENTA}${TXT_BOLD}Creating a VPC network and VM instance...${TXT_RESET}"
gcloud compute networks create mynetwork --subnet-mode=auto
gcloud compute instances create default-us-vm \
--machine-type=e2-micro \
--zone="$DEFAULT_ZONE" --network=mynetwork

# Step 9: Deleting the bucket and capturing logs
echo -e "${CLR_GREEN}${TXT_BOLD}Deleting the bucket and capturing logs...${TXT_RESET}"
gsutil rm -r gs://$DEVSHELL_PROJECT_ID

gcloud logging read \
"logName=projects/$DEVSHELL_PROJECT_ID/logs/cloudaudit.googleapis.com%2Factivity \
AND protoPayload.serviceName=storage.googleapis.com \
AND protoPayload.methodName=storage.buckets.delete"

# Step 10: Creating and testing another bucket
echo -e "${CLR_YELLOW}${TXT_BOLD}Creating and testing another bucket...${TXT_RESET}"
gsutil mb gs://$DEVSHELL_PROJECT_ID
gsutil mb gs://$DEVSHELL_PROJECT_ID-test
echo "this is another sample file" > sample2.txt
gsutil cp sample.txt gs://$DEVSHELL_PROJECT_ID-test

# Step 11: Deleting the VM instance and logging
echo -e "${CLR_RED}${TXT_BOLD}Deleting the VM instance and logging...${TXT_RESET}"
gcloud compute instances delete --zone="$DEFAULT_ZONE" \
--delete-disks=all default-us-vm --quiet

# Step 12: Deleting the bucket and capturing logs
echo -e "${CLR_GREEN}${TXT_BOLD}Deleting the bucket and capturing logs...${TXT_RESET}"
gsutil rm -r gs://$DEVSHELL_PROJECT_ID
gsutil rm -r gs://$DEVSHELL_PROJECT_ID-test

# Step 13: BigQuery query for instance deletion logs
echo -e "${CLR_CYAN}${TXT_BOLD}Querying BigQuery for instance deletion logs...${TXT_RESET}"
bq query --nouse_legacy_sql --project_id=$DEVSHELL_PROJECT_ID '
SELECT
  timestamp,
  resource.labels.instance_id,
  protopayload_auditlog.authenticationInfo.principalEmail,
  protopayload_auditlog.resourceName,
  protopayload_auditlog.methodName
FROM
  auditlogs_dataset.cloudaudit_googleapis_com_activity_*
WHERE
  PARSE_DATE("%Y%m%d", _TABLE_SUFFIX) BETWEEN
  DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) AND
  CURRENT_DATE()
  AND resource.type = "gce_instance"
  AND operation.first IS TRUE
  AND protopayload_auditlog.methodName = "v1.compute.instances.delete"
ORDER BY
  timestamp,
  resource.labels.instance_id
LIMIT
  1000'

# Step 14: BigQuery query for bucket deletion logs
echo -e "${CLR_BLUE}${TXT_BOLD}Querying BigQuery for bucket deletion logs...${TXT_RESET}"
bq query --nouse_legacy_sql --project_id=$DEVSHELL_PROJECT_ID '
SELECT
  timestamp,
  resource.labels.bucket_name,
  protopayload_auditlog.authenticationInfo.principalEmail,
  protopayload_auditlog.resourceName,
  protopayload_auditlog.methodName
FROM
  auditlogs_dataset.cloudaudit_googleapis_com_activity_*
WHERE
  PARSE_DATE("%Y%m%d", _TABLE_SUFFIX) BETWEEN
  DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) AND
  CURRENT_DATE()
  AND resource.type = "gcs_bucket"
  AND protopayload_auditlog.methodName = "storage.buckets.delete"
ORDER BY
  timestamp,
  resource.labels.bucket_name
LIMIT
  1000'

echo

# Function to display a random congratulatory message
function random_message() {
    MSGS=(
        "${CLR_GREEN}Congratulations For Completing The Lab! Keep up the great work!${TXT_RESET}"
        "${CLR_CYAN}Well done! Your hard work and effort have paid off!${TXT_RESET}"
        # Additional messages...
    )

    RAND_INDEX=$((RANDOM % ${#MSGS[@]}))
    echo -e "${TXT_BOLD}${MSGS[$RAND_INDEX]}"
}

# Display a random congratulatory message
random_message

echo -e "\n"  # Adding one blank line

cd

cleanup_files() {
    # Loop through all files in the current directory
    for file_item in *; do
        # Check if the file name contains "txt"
        if [[ $file_item == *"txt"* ]]; then
            # Delete the file
            rm "$file_item"
        fi
    done
}

# Cleanup unnecessary files in the home directory
cleanup_files
