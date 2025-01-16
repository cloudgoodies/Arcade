#!/bin/bash
# Define color variables with updated codes
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

# Updated array of color codes (using a different combination)
TEXT_COLORS=($CYAN $MAGENTA $YELLOW $RED $BLUE $WHITE)
BG_COLORS=($BG_GREEN $BG_MAGENTA $BG_YELLOW $BG_BLUE $BG_CYAN $BG_RED)

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

#----------------------------------------------------start--------------------------------------------------#

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

gcloud source repos create devsite

echo

# Function to display a random congratulatory message
function random_congrats() {
    MESSAGES=(
        "${CYAN}Awesome work! You're building a solid foundation for success.${RESET}"
        "${MAGENTA}Congratulations! Your effort today will lead to even greater achievements.${RESET}"
        "${YELLOW}Great job! You’ve taken another big step forward.${RESET}"
        "${RED}Amazing! Your determination and focus are paying off.${RESET}"
        "${BLUE}Fantastic! You’re proving that hard work brings results.${RESET}"
        "${GREEN}Outstanding! You’ve earned this success through perseverance.${RESET}"
        "${CYAN}Keep it up! This is what progress looks like.${RESET}"
        "${MAGENTA}Impressive work! You’re moving closer to your goals.${RESET}"
        "${YELLOW}You’re unstoppable! This is just the beginning of your journey.${RESET}"
        "${RED}Well done! You’ve demonstrated great skill and dedication.${RESET}"
        "${BLUE}Excellent effort! You’re on the right path to mastery.${RESET}"
        "${GREEN}Congratulations! Your commitment is inspiring!${RESET}"
    )

    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

# Display a random congratulatory message
random_congrats

echo -e "\n"  # Adding one blank line

cd

# Updated remove_files function using a different approach
remove_files() {
    # Use find to locate and delete files matching patterns
    find . -maxdepth 1 -type f \( -name "gsp*" -o -name "arc*" -o -name "shell*" \) -exec rm -v {} +
}

# Call the remove_files function
remove_files
