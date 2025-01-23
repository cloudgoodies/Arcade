#!/bin/bash

# Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging Function with Color
log() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] $message${NC}"
}

# Error Handling Function
handle_error() {
    log $RED "Error: $1"
    exit 1
}

# Validate Project and Configuration
validate_config() {
    log $BLUE "Validating Google Cloud configuration..."
    PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null) || handle_error "Unable to retrieve project ID"
    ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
    REGION=${ZONE%-*}

    log $GREEN "Project: $PROJECT_ID"
    log $GREEN "Zone: $ZONE"
    log $GREEN "Region: $REGION"
}

# Enable Required Services with Retry
enable_services() {
    local services=("cloudfunctions.googleapis.com" "run.googleapis.com" "cloudscheduler.googleapis.com")
    
    for service in "${services[@]}"; do
        log $YELLOW "Enabling service: $service"
        gcloud services disable "$service" 2>/dev/null
        gcloud services enable "$service" || handle_error "Failed to enable $service"
    done
    sleep 30
}

# IAM Policy Binding
configure_iam_policy() {
    log $BLUE "Configuring IAM Policy..."
    PROJECT_NUMBER=$(gcloud projects describe "$DEVSHELL_PROJECT_ID" --format='value(projectNumber)')
    
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$PROJECT_ID@appspot.gserviceaccount.com" \
        --role="roles/artifactregistry.reader" || handle_error "Failed to add IAM policy binding"
}

# Create IP Addresses
create_ip_addresses() {
    local used_ip="used-ip-address"
    local unused_ip="unused-ip-address"

    log $BLUE "Creating IP Addresses..."
    gcloud compute addresses create "$used_ip" --project="$PROJECT_ID" --region="$REGION"
    sleep 5
    gcloud compute addresses create "$unused_ip" --project="$PROJECT_ID" --region="$REGION"
    sleep 15

    gcloud compute addresses list --filter="region:($REGION)"
    
    # Get Used IP Address
    USED_IP_ADDRESS=$(gcloud compute addresses describe "$used_ip" --region="$REGION" --format=json | jq -r '.address')
    
    # Create Compute Instance
    gcloud compute instances create static-ip-instance \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --machine-type=e2-medium \
        --subnet=default \
        --address="$USED_IP_ADDRESS" || handle_error "Failed to create compute instance"
}

# Prepare Function Code
prepare_function_code() {
    log $BLUE "Preparing Function Code..."
    # Clone Repository
    git clone https://github.com/GoogleCloudPlatform/gcf-automated-resource-cleanup.git
    cd gcf-automated-resource-cleanup/ || handle_error "Failed to change directory"
    
    # Verify function.js exists and contains expected content
    if [ ! -f "unused-ip/function.js" ]; then
        handle_error "function.js not found"
    fi
    
    cat unused-ip/function.js | grep "const compute" -A 31
}

# Deploy Cloud Function with Enhanced Retry Logic
deploy_function() {
    local max_attempts=5
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        log $YELLOW "Deployment Attempt $attempt of $max_attempts"
        
        gcloud functions deploy unused_ip_function \
            --gen2 \
            --trigger-http \
            --runtime=nodejs20 \
            --region="$REGION" \
            --allow-unauthenticated \
            --quiet

        if gcloud functions describe unused_ip_function --region="$REGION" &> /dev/null; then
            log $GREEN "Function deployed successfully."
            FUNCTION_URL=$(gcloud functions describe unused_ip_function --region="$REGION" --format=json | jq -r '.url')
            return 0
        fi

        log $RED "Deployment failed. Retrying..."
        ((attempt++))
        sleep 20
    done

    handle_error "Function deployment failed after $max_attempts attempts"
}

# Create App Engine Application
create_app_engine() {
    log $BLUE "Creating App Engine Application..."
    if [ "$REGION" == "us-central1" ]; then
        gcloud app create --region us-central
    else
        gcloud app create --region "$REGION"
    fi || handle_error "Failed to create App Engine application"
}

# Schedule and Run Job with Robust Error Handling
schedule_and_run_job() {
    log $YELLOW "Scheduling and Running IP Cleanup Job..."
    
    gcloud scheduler jobs create http unused-ip-job \
        --schedule="* 2 * * *" \
        --uri="$FUNCTION_URL" \
        --location="$REGION" || handle_error "Failed to create scheduler job"

    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if gcloud scheduler jobs run unused-ip-job --location="$REGION"; then
            log $GREEN "Job ran successfully."
            return 0
        fi

        log $RED "Job run failed. Attempt $attempt of $max_attempts"
        ((attempt++))
        sleep 10
    done

    handle_error "Failed to run scheduled job"
}

# Verify and List Addresses
verify_addresses() {
    log $BLUE "Verifying IP Addresses..."
    gcloud compute addresses list --filter="region:($REGION)"
    
    # Create Additional Unused IP
    local unused_ip="unused-ip-address"
    gcloud compute addresses create "$unused_ip" --project="$PROJECT_ID" --region="$REGION"
    sleep 15
    
    gcloud compute addresses list --filter="region:($REGION)"
}

# Main Execution Flow
main() {
    log $GREEN "Starting Google Cloud IP Cleanup Process"
    
    validate_config
    enable_services
    configure_iam_policy
    
    prepare_function_code
    create_ip_addresses
    deploy_function
    create_app_engine
    schedule_and_run_job
    verify_addresses

    log $GREEN "IP Cleanup Process Completed Successfully!"
}

# Execute Main Function
main
