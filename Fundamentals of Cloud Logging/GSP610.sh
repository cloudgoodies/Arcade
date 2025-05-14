clear

#!/bin/bash
# Define color variables

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`

# Array of color codes excluding black and white
TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

#----------------------------------------------------start--------------------------------------------------#

echo "${BG_GREEN}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

# Step 1: Authenticate Account
echo "${BOLD}${YELLOW}Authenticating Account...${RESET}"
gcloud auth application-default login --quiet

# Step 2: Set Project ID
echo "${BOLD}${YELLOW}Setting Project ID...${RESET}"
export PROJECT_ID=$(gcloud config get-value project)

# Step 3: Set Project Number
echo "${BOLD}${YELLOW}Setting Project Number...${RESET}"
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} \
    --format="value(projectNumber)")

# Step 4: Set Compute Zone
echo "${BOLD}${YELLOW}Setting Compute Zone...${RESET}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Step 5: Set Compute Region
echo "${BOLD}${YELLOW}Setting Compute Region...${RESET}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 6: Enable OS Config API
echo "${BOLD}${YELLOW}Enabling OS Config API...${RESET}"
gcloud services enable osconfig.googleapis.com

# Step 7: Configure Compute Zone
echo "${BOLD}${YELLOW}Configuring Compute Zone...${RESET}"
gcloud config set compute/zone $ZONE

# Step 8: Configure Compute Region
echo "${BOLD}${YELLOW}Configuring Compute Region...${RESET}"
gcloud config set compute/region $REGION

# Step 9: Create Logging Metric
echo "${BOLD}${YELLOW}Creating Logging Metric...${RESET}"
gcloud logging metrics create 200responses \
--description="Counts successful HTTP 200 responses from the default GAE service" \
--log-filter='resource.type="gae_app"
resource.labels.module_id="default"
(protoPayload.status=200 OR httpRequest.status=200)'

# Step 10: Create Latency Metric
echo "${BOLD}${BLUE}Creating Latency Metric...${RESET}"
cat > metric.json <<EOF
{
  "name": "latency_metric",
  "description": "latency distribution",
  "filter": "resource.type=\"gae_app\" AND resource.labels.module_id=\"default\" AND logName=(\"projects/${PROJECT_ID}/logs/cloudbuild\" OR \"projects/${PROJECT_ID}/logs/stderr\" OR \"projects/${PROJECT_ID}/logs/%2Fvar%2Flog%2Fgoogle_init.log\" OR \"projects/${PROJECT_ID}/logs/appengine.googleapis.com%2Frequest_log\" OR \"projects/${PROJECT_ID}/logs/cloudaudit.googleapis.com%2Factivity\") AND severity>=DEFAULT",
  "valueExtractor": "EXTRACT(protoPayload.latency)",
  "metricDescriptor": {
    "metricKind": "DELTA",
    "valueType": "DISTRIBUTION",
    "unit": "s",
    "labels": []
  },
  "bucketOptions": {
    "explicitBuckets": {
      "bounds": [0.01, 0.1, 0.5, 1, 2, 5]
    }
  }
}
EOF

curl -X POST \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  -d @metric.json \
  "https://logging.googleapis.com/v2/projects/${PROJECT_ID}/metrics"

# Step 11: Create VM Instance
echo "${BOLD}${YELLOW}Creating VM Instance...${RESET}"
gcloud compute instances create quickgcplab \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-micro \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --metadata=enable-osconfig=TRUE,enable-oslogin=true \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append \
    --tags=http-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=quickgcplab,image=projects/debian-cloud/global/images/debian-12-bookworm-v20250415,mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ops-agent-policy=v2-x86-template-1-4-0,goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any \
&& \
printf 'agentsRule:\n  packageState: installed\n  version: latest\ninstanceFilter:\n  inclusionLabels:\n  - labels:\n      goog-ops-agent-policy: v2-x86-template-1-4-0\n' > config.yaml \
&& \
gcloud compute instances ops-agents policies create goog-ops-agent-v2-x86-template-1-4-0-$ZONE \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --file=config.yaml \
&& \
gcloud compute resource-policies create snapshot-schedule default-schedule-1 \
    --project=$DEVSHELL_PROJECT_ID \
    --region=$REGION \
    --max-retention-days=14 \
    --on-source-disk-delete=keep-auto-snapshots \
    --daily-schedule \
    --start-time=17:00 \
&& \
gcloud compute disks add-resource-policies quickgcplab \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --resource-policies=projects/$DEVSHELL_PROJECT_ID/regions/$REGION/resourcePolicies/default-schedule-1

# Step 12: Create BigQuery Dataset
echo "${BOLD}${CYAN}Creating BigQuery Dataset...${RESET}"
bq --location=US mk --dataset ${PROJECT_ID}:AuditLogs

# Step 13: Create Logging Sink
echo "${BOLD}${RED}Creating Logging Sink...${RESET}"
gcloud logging sinks create AuditLogs \
  bigquery.googleapis.com/projects/$PROJECT_ID/datasets/AuditLogs \
  --log-filter='resource.type="gce_instance"' \
  --project=$PROJECT_ID

# Step 14: Open Application
echo "${BOLD}${GREEN}Opening Application...${RESET}"
URL=$(gcloud app browse --no-launch-browser --format="value(url)")

echo

echo "${BOLD}${BLUE}Check out your app by clicking here: ${RESET}"$URL

echo

# Function to display a random congratulatory message
function random_congrats() {
    MESSAGES=(
        "${GREEN}Congratulations For Completing The Lab! Keep up the great work!${RESET}"
       
    )

    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

# Display a random congratulatory message
random_congrats

echo -e "\n"  # Adding one blank line

cd

remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with "gsp", "arc", or "shell"
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            # Check if it's a regular file (not a directory)
            if [[ -f "$file" ]]; then
                # Remove the file and echo the file name
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

remove_files
