# Define color variables for text formatting
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

# Define color variables for background formatting
BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

# Define formatting variables
BOLD=$(tput bold)
RESET=$(tput sgr0)

# -------------------------------------------------- Start --------------------------------------------------

# Notify user of the start
echo "${YELLOW}${BOLD}Starting${RESET} ${GREEN}${BOLD}Execution${RESET}"

# Enable required Google Cloud service
gcloud services enable appengine.googleapis.com

# Pause for a few seconds to allow the service to be enabled
sleep 10

# Set the desired region for Google Cloud resources
gcloud config set compute/region $REGION

# Clone the necessary GitHub repository
git clone https://github.com/GoogleCloudPlatform/golang-samples.git

# Navigate to the appropriate directory
cd golang-samples/appengine/go11x/helloworld

# Install the Google Cloud SDK for Go
sudo apt-get install google-cloud-sdk-app-engine-go

# Deploy the application to Google Cloud App Engine
gcloud app deploy

# Notify user upon completion
echo "${GREEN}${BOLD}Congratulations${RESET} ${GREEN}${BOLD}for${RESET} ${GREEN}${BOLD}Completing the Lab !!!${RESET}"

# -------------------------------------------------- End --------------------------------------------------
