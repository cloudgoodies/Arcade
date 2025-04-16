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

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

# Step 1: Set ZONE and REGION
echo "${BOLD}${CYAN}Setting ZONE and REGION${RESET}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Enable required services
echo "${BOLD}${YELLOW}Enabling APIs (Cloud Functions, Cloud Run)${RESET}"
gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

gcloud services enable cloudfunctions.googleapis.com

gcloud services enable run.googleapis.com

# Step 3: Download Go samples
echo "${BOLD}${GREEN}Downloading Go Samples from GitHub${RESET}"
curl -LO https://github.com/GoogleCloudPlatform/golang-samples/archive/main.zip

# Step 4: Unzip the downloaded file
echo "${BOLD}${BLUE}Unzipping downloaded samples${RESET}"
unzip main.zip

# Step 5: Change directory to sample function
echo "${BOLD}${MAGENTA}Navigating to Gopher function directory${RESET}"
cd golang-samples-main/functions/codelabs/gopher

# Step 6: Deploy HelloWorld function
echo "${BOLD}${CYAN}Deploying HelloWorld function${RESET}"
gcloud functions deploy HelloWorld --gen2 --runtime go121 --trigger-http --region $REGION --allow-unauthenticated

# Step 7: Test HelloWorld function
echo "${BOLD}${YELLOW}Testing HelloWorld function${RESET}"
curl https://$REGION-$GOOGLE_CLOUD_PROJECT.cloudfunctions.net/HelloWorld

# Step 8: Deploy Gopher function
echo "${BOLD}${GREEN}Deploying Gopher function${RESET}"
gcloud functions deploy Gopher --gen2 --runtime go121 --trigger-http --region $REGION --allow-unauthenticated

echo

# Function to display a random congratulatory message
function random_congrats() {
    MESSAGES=(
        "${GREEN}Congratulations For Completing The Lab!!${RESET}"
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
