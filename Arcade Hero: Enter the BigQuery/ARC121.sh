#!/bin/bash

# Define text color codes
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

# Define background color codes
BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

# Define text formatting codes
BOLD=$(tput bold)
RESET=$(tput sgr0)

#----------------------------------------------------start--------------------------------------------------#

# Notify the user that the process is starting
echo "${YELLOW}${BOLD}Starting${RESET} ${GREEN}${BOLD}Execution${RESET}"

# Create BigQuery dataset
bq --location=US mk --dataset "$DEVSHELL_PROJECT_ID:$DATASET"

# Notify the user of completion
echo "${GREEN}${BOLD}Congratulations${RESET} ${GREEN}${BOLD}for${RESET} ${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
