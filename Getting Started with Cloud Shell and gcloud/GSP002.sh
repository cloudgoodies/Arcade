# Define text and background colors
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

#----------------------------------------------------start--------------------------------------------------#

# Display starting message with new colors
echo "${CYAN}${BOLD}Initializing${RESET}" "${MAGENTA}${BOLD}Execution${RESET}"

# Set region and zone configuration
export REGION="${ZONE%-*}"
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

# Get project ID and create an instance
export PROJECT_ID=$(gcloud config get-value project)
gcloud compute instances create gcelab2 --machine-type e2-medium --zone $ZONE

# Display completion message with new colors
echo "${BLUE}${BOLD}Well Done!${RESET}" "${YELLOW}${BOLD}You${RESET}" "${GREEN}${BOLD}Completed the Lab Successfully!!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
