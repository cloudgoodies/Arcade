#!/bin/bash

# Define color variables for formatting
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

# Display starting message with colored output
echo "${YELLOW}${BOLD}Starting${RESET} ${GREEN}${BOLD}Execution${RESET}"

# Create the soccer dataset in BigQuery
bq --location=us mk --dataset "$DEVSHELL_PROJECT_ID:soccer"

# Task 3: Load soccer data into BigQuery
bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON "$DEVSHELL_PROJECT_ID:soccer.competitions" gs://spls/bq-soccer-analytics/competitions.json
bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON "$DEVSHELL_PROJECT_ID:soccer.matches" gs://spls/bq-soccer-analytics/matches.json
bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON "$DEVSHELL_PROJECT_ID:soccer.teams" gs://spls/bq-soccer-analytics/teams.json
bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON "$DEVSHELL_PROJECT_ID:soccer.players" gs://spls/bq-soccer-analytics/players.json
bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON "$DEVSHELL_PROJECT_ID:soccer.events" gs://spls/bq-soccer-analytics/events.json

# Task 4: Load CSV data for tags2name
bq load --autodetect --source_format=CSV "$DEVSHELL_PROJECT_ID:soccer.tags2name" gs://spls/bq-soccer-analytics/tags2name.csv

# Task 6: Query to find top 5 tallest defenders
bq query --use_legacy_sql=false \
"
SELECT
  CONCAT(firstName, ' ', lastName) AS player,
  birthArea.name AS birthArea,
  height
FROM
  \`soccer.players\`
WHERE
  role.name = 'Defender'
ORDER BY
  height DESC
LIMIT 5
"

# Task 7: Query to get events count by event ID
bq query --use_legacy_sql=false \
"
SELECT
  eventId,
  eventName,
  COUNT(id) AS numEvents
FROM
  \`soccer.events\`
GROUP BY
  eventId, eventName
ORDER BY
  numEvents DESC
"

# Display completion message with colored output
echo "${GREEN}${BOLD}Congratulations${RESET} ${GREEN}${BOLD}for${RESET} ${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
