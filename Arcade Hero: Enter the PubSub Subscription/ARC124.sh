# Define color codes
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

#----------------------------------------------------start--------------------------------------------------#

# Display start message
printf "%s%sStarting%s %s%sExecution%s\n" "$YELLOW" "$BOLD" "$RESET" "$GREEN" "$BOLD" "$RESET"

# Create Pub/Sub topics
gcloud pubsub topics create "$TOPIC_ID1"
gcloud pubsub topics create "$TOPIC_ID2"

# Create Pub/Sub subscription
gcloud pubsub subscriptions create "$SUBS_ID" --topic="$TOPIC_ID2"

# Display completion message
printf "%s%sCongratulations%s %s%sfor%s %s%sCompleting the Lab !!!%s\n" \
  "$RED" "$BOLD" "$RESET" "$WHITE" "$BOLD" "$RESET" "$GREEN" "$BOLD" "$RESET"

#-----------------------------------------------------end----------------------------------------------------------#
