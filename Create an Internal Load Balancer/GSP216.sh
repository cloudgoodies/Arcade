#!/bin/bash

# Enhanced color definitions using tput with descriptive names
declare -A COLORS=(
    ["PRIMARY"]=$(tput setaf 6)     # Cyan
    ["SUCCESS"]=$(tput setaf 2)     # Green
    ["WARNING"]=$(tput setaf 3)     # Yellow
    ["ERROR"]=$(tput setaf 1)       # Red
    ["INFO"]=$(tput setaf 4)        # Blue
    ["ACCENT"]=$(tput setaf 5)      # Magenta
    ["RESET"]=$(tput sgr0)
    ["BOLD"]=$(tput bold)
)

# Enhanced background colors
declare -A BG_COLORS=(
    ["PRIMARY"]=$(tput setab 6)
    ["SUCCESS"]=$(tput setab 2)
    ["WARNING"]=$(tput setab 3)
    ["ERROR"]=$(tput setab 1)
    ["INFO"]=$(tput setab 4)
    ["ACCENT"]=$(tput setab 5)
)

# Create arrays of color codes for random selection (excluding reset and bold)
TEXT_COLORS=(
    "${COLORS[PRIMARY]}" 
    "${COLORS[SUCCESS]}" 
    "${COLORS[WARNING]}" 
    "${COLORS[ERROR]}" 
    "${COLORS[INFO]}" 
    "${COLORS[ACCENT]}"
)

BG_COLOR_LIST=(
    "${BG_COLORS[PRIMARY]}" 
    "${BG_COLORS[SUCCESS]}" 
    "${BG_COLORS[WARNING]}" 
    "${BG_COLORS[ERROR]}" 
    "${BG_COLORS[INFO]}" 
    "${BG_COLORS[ACCENT]}"
)

# Select random colors for variety
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLOR_LIST[$RANDOM % ${#BG_COLOR_LIST[@]}]}

# Enhanced logging function
log_message() {
    local color=$1
    local message=$2
    echo -e "${COLORS[BOLD]}${COLORS[$color]}$message${COLORS[RESET]}"
}

# Enhanced zone change function
change_zone_automatically() {
    if [[ -z "$ZONE_1" ]]; then
        log_message "ERROR" "❌ Could not retrieve the current zone. Exiting."
        return 1
    }

    log_message "INFO" "📍 Current Zone (ZONE_1): $ZONE_1"

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
    log_message "SUCCESS" "✅ New Zone (ZONE_2) is now set to: $ZONE_2"
}

#----------------------------------------------------start--------------------------------------------------#

log_message "PRIMARY" "🚀 Starting GCP Internal Load Balancer Setup"

# Step 1: Retrieve default zone and region
log_message "INFO" "📡 Retrieving default zone and region..."
export ZONE_1=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Create firewall rule to allow HTTP traffic
log_message "INFO" "🔒 Creating firewall rule for HTTP traffic..."
gcloud compute firewall-rules create app-allow-http \
    --direction=INGRESS \
    --priority=1000 \
    --network=my-internal-app \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=10.10.0.0/16 \
    --target-tags=lb-backend

# Step 3: Create firewall rule to allow health checks
log_message "INFO" "🏥 Creating firewall rule for health checks..."
gcloud compute firewall-rules create app-allow-health-check \
    --direction=INGRESS \
    --priority=1000 \
    --network=my-internal-app \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=lb-backend

# Step 4: Create instance template for subnet-a
log_message "INFO" "🔧 Creating instance template for subnet-a..."
gcloud compute instance-templates create instance-template-1 \
    --machine-type e2-micro \
    --network my-internal-app \
    --subnet subnet-a \
    --tags lb-backend \
    --metadata startup-script-url=gs://cloud-training/gcpnet/ilb/startup.sh \
    --region=$REGION

# Step 5: Create instance template for subnet-b
log_message "INFO" "🔧 Creating instance template for subnet-b..."
gcloud compute instance-templates create instance-template-2 \
    --machine-type e2-micro \
    --network my-internal-app \
    --subnet subnet-b \
    --tags lb-backend \
    --metadata startup-script-url=gs://cloud-training/gcpnet/ilb/startup.sh \
    --region=$REGION

# Step 6: Determine and set the secondary zone
log_message "INFO" "🌐 Setting up secondary zone..."
change_zone_automatically

# Step 7: Create instance group 1
log_message "INFO" "📦 Creating managed instance group 1..."
gcloud beta compute instance-groups managed create instance-group-1 \
    --project=$DEVSHELL_PROJECT_ID \
    --base-instance-name=instance-group-1 \
    --size=1 \
    --template=instance-template-1 \
    --zone=$ZONE_1 \
    --list-managed-instances-results=PAGELESS \
    --no-force-update-on-repair

# Step 8: Set autoscaling for instance group 1
log_message "INFO" "⚖️ Configuring autoscaling for instance group 1..."
gcloud beta compute instance-groups managed set-autoscaling instance-group-1 \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE_1 \
    --cool-down-period=45 \
    --max-num-replicas=5 \
    --min-num-replicas=1 \
    --mode=on \
    --target-cpu-utilization=0.8

# Step 9: Create instance group 2
log_message "INFO" "📦 Creating managed instance group 2..."
gcloud beta compute instance-groups managed create instance-group-2 \
    --project=$DEVSHELL_PROJECT_ID \
    --base-instance-name=instance-group-2 \
    --size=1 \
    --template=instance-template-2 \
    --zone=$ZONE_2 \
    --list-managed-instances-results=PAGELESS \
    --no-force-update-on-repair

# Step 10: Set autoscaling for instance group 2
log_message "INFO" "⚖️ Configuring autoscaling for instance group 2..."
gcloud beta compute instance-groups managed set-autoscaling instance-group-2 \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE_2 \
    --cool-down-period=45 \
    --max-num-replicas=5 \
    --min-num-replicas=1 \
    --mode=on \
    --target-cpu-utilization=0.8

# Step 11: Create utility VM
log_message "INFO" "🖥️ Creating utility VM..."
gcloud compute instances create utility-vm \
    --zone $ZONE_1 \
    --machine-type e2-micro \
    --network my-internal-app \
    --subnet subnet-a \
    --private-network-ip 10.10.20.50

# Step 12: Create health check
log_message "INFO" "🏥 Creating health check..."
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -d '{
    "checkIntervalSec": 5,
    "description": "",
    "healthyThreshold": 2,
    "name": "my-ilb-health-check",
    "region": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'",
    "tcpHealthCheck": {
      "port": 80,
      "proxyHeader": "NONE"
    },
    "timeoutSec": 5,
    "type": "TCP",
    "unhealthyThreshold": 2
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/healthChecks"

sleep 30 

# Step 13: Create backend service
log_message "INFO" "🔧 Creating backend service..."
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -d '{
    "backends": [
      {
        "balancingMode": "CONNECTION",
        "failover": false,
        "group": "projects/'"$DEVSHELL_PROJECT_ID"'/zones/'"$ZONE_1"'/instanceGroups/instance-group-1"
      },
      {
        "balancingMode": "CONNECTION",
        "failover": false,
        "group": "projects/'"$DEVSHELL_PROJECT_ID"'/zones/'"$ZONE_2"'/instanceGroups/instance-group-2"
      }
    ],
    "connectionDraining": {
      "drainingTimeoutSec": 300
    },
    "description": "",
    "failoverPolicy": {},
    "healthChecks": [
      "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'/healthChecks/my-ilb-health-check"
    ],
    "loadBalancingScheme": "INTERNAL",
    "logConfig": {
      "enable": false
    },
    "name": "my-ilb",
    "network": "projects/'"$DEVSHELL_PROJECT_ID"'/global/networks/my-internal-app",
    "protocol": "TCP",
    "region": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'",
    "sessionAffinity": "NONE"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/backendServices"

sleep 20

# Step 14: Create forwarding rule
log_message "INFO" "🔄 Creating forwarding rule..."
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -d '{
    "IPAddress": "10.10.30.5",
    "IPProtocol": "TCP",
    "allowGlobalAccess": false,
    "backendService": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'/backendServices/my-ilb",
    "description": "",
    "ipVersion": "IPV4",
    "loadBalancingScheme": "INTERNAL",
    "name": "my-ilb-forwarding-rule",
    "networkTier": "PREMIUM",
    "ports": [
      "80"
    ],
    "region": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'",
    "subnetwork": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'/subnetworks/subnet-b"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/forwardingRules"

# Enhanced congratulatory messages function
function display_congratulations() {
    MESSAGES=(
        "🎉 Outstanding achievement! Your dedication shines through!"
        "🌟 Phenomenal work! You've mastered this challenge!"
        "🏆 Exceptional performance! Keep reaching for the stars!"
        "🎯 Bulls-eye! You've hit all the targets perfectly!"
        "🚀 Launching towards success! Amazing work!"
        "💫 Stellar performance! You're truly exceptional!"
        "🌈 Brilliant execution! Your skills are impressive!"
        "⭐ You're a star! Outstanding completion!"
        "🎊 Magnificent work! You've conquered this challenge!"
        "💪 Powerful performance! You're unstoppable!"
    )

    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    log_message "SUCCESS" "${MESSAGES[$RANDOM_INDEX]}"
}

# Enhanced file cleanup function
cleanup_files() {
    local removed_count=0
    log_message "INFO" "🧹 Starting cleanup process..."
    
    for file in *; do
        if [[ "$file" =~ ^(gsp|arc|shell) && -f "$file" ]]; then
            rm "$file"
            ((removed_count++))
            log_message "INFO" "🗑️  Removed: $file"
        fi
    done
    
    log_message "SUCCESS" "✨ Cleanup complete! Removed $removed_count files."
}

# Display completion message and cleanup
display_congratulations
echo -e "\n"
cleanup_files

cd
