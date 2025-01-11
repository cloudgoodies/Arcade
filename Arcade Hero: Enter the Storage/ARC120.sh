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

#---------------------------------------------------- Start ----------------------------------------------------#

echo "${BG_MAGENTA}${BOLD}Starting Execution...${RESET}"

# Retrieve project details
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$PROJECT_ID" --format="value(project_number)")

# Clone the repository and navigate to the appropriate directory
git clone https://github.com/GoogleCloudPlatform/golang-samples.git
cd golang-samples/functions/functionsv2/hellostorage/ || exit 1

# Function to deploy the Cloud Function
deploy_function() {
  gcloud functions deploy cf-demo \
    --runtime=go121 \
    --region="$REGION" \
    --source=. \
    --entry-point=HelloStorage \
    --trigger-bucket="${DEVSHELL_PROJECT_ID}-bucket"
}

# Variables
SERVICE_NAME="cf-demo"

# Loop until the Cloud Function is successfully deployed
while true; do
  echo "Attempting to deploy the Cloud Function..."
  deploy_function

  if gcloud functions describe "$SERVICE_NAME" --region "$REGION" &> /dev/null; then
    echo "${GREEN}Cloud Function is deployed successfully.${RESET}"
    break
  else
    echo "${YELLOW}Deployment not completed. Retrying in 30 seconds...${RESET}"
    sleep 30
  fi
done

echo "${BG_RED}${BOLD}Congratulations on Completing the Lab!${RESET}"

#----------------------------------------------------- End ------------------------------------------------------#
