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

#---------------------------------------------------- START --------------------------------------------------#

echo "${GREEN}${WHITE}${BOLD}>> Starting Execution...${RESET}"

# Create a Pub/Sub topic
gcloud pubsub topics create myTopic

# Create a Pub/Sub subscription
gcloud pubsub subscriptions create --topic myTopic MySub

# Completion message
echo "${BG_GREEN}${BLACK}${BOLD}>> Congratulations on Completing the Lab!${RESET}"

#----------------------------------------------------- END ----------------------------------------------------------#
