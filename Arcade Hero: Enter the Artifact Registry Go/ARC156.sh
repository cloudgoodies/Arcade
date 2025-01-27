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

echo "${GREEN}${BOLD}Starting${RESET}" "${MAGENTA}${BOLD}Execution${RESET}"

gcloud artifacts repositories create $REPO --repository-format=go --location=$REGION

echo "${GREEN}${BOLD}Congratulations${RESET}" "${YELLOW}${BOLD}for${RESET}" "${RED}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
