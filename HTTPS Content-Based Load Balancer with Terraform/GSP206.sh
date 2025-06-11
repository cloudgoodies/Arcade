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

# Step 1: Set up the environment
echo "${GREEN}${BOLD}Setting up the environment...${RESET}"
update_regions() {
  read -p "${YELLOW}${BOLD}Enter value for REGION2: ${RESET}" REGION2
  read -p "${BLUE}${BOLD}Enter value for REGION3: ${RESET}" REGION3

  export REGION1=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
  export REGION2
  export REGION3
}

update_regions

# Step 2: Clone the repository
echo "${RED}${BOLD}Cloning the repository...${RESET}"
git clone https://github.com/terraform-google-modules/terraform-google-lb-http.git

# Step 3: Navigate to the example directory
echo "${GREEN}${BOLD}Navigating to the example directory...${RESET}"
cd ~/terraform-google-lb-http/examples/multi-backend-multi-mig-bucket-https-lb

# Step 4: Remove existing Terraform files
echo "${GREEN}${BOLD}Removing existing Terraform files...${RESET}"
rm -rf main.tf
rm -rf variables.tf

# Step 5: Download the Terraform files
echo "${GREEN}${BOLD}Downloading Terraform files...${RESET}"
wget https://github.com/cloudgoodies/Arcade/blob/main/HTTPS%20Content-Based%20Load%20Balancer%20with%20Terraform/variables.tf
wget https://github.com/cloudgoodies/Arcade/blob/main/HTTPS%20Content-Based%20Load%20Balancer%20with%20Terraform/main.tf

# Step 6: Update the Terraform files with the region variables
echo "${MAGENTA}${BOLD}Updating Terraform files with region variables...${RESET}"
sed -i "s/default = \"REGION1\"/default = \"$REGION1\"/" variables.tf
sed -i "s/default = \"REGION2\"/default = \"$REGION2\"/" variables.tf
sed -i "s/default = \"REGION3\"/default = \"$REGION3\"/" variables.tf

# Step 7: Initialize Terraform
echo "${GREEN}${BOLD}Initializing Terraform...${RESET}"
terraform init

# Step 8: Validate the Terraform configuration
echo "${GREEN}${BOLD}Validating the Terraform configuration...${RESET}"
terraform plan -out=tfplan -var "project=$DEVSHELL_PROJECT_ID"

# Step 9: Apply the Terraform plan
echo "${GREEN}${BOLD}Applying the Terraform plan...${RESET}"
terraform apply tfplan

echo

# Function to display a random congratulatory message
function random_congrats() {
    MESSAGES=(
        "${GREEN}Congratulations For Completing The Lab !!${RESET}"
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
