# Define text and background color variables using tput
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

#------------------------------------------- Script Start ------------------------------------------------#

# Display starting message
echo "${YELLOW}${BOLD}Starting${RESET} ${GREEN}${BOLD}Execution${RESET}"

# Execute a BigQuery query to fetch the top 10 heaviest babies
bq query --use_legacy_sql=false <<EOF
#standardSQL
SELECT
  weight_pounds, state, year, gestation_weeks
FROM
  \`bigquery-public-data.samples.natality\`
ORDER BY weight_pounds DESC
LIMIT 10;
EOF

# Create a new BigQuery dataset
bq mk babynames

# Load data into the dataset from a Google Cloud Storage bucket
bq load \
  --autodetect \
  --source_format=CSV \
  babynames.names_2014 \
  gs://spls/gsp072/baby-names/yob2014.txt \
  name:string,gender:string,count:integer

# Execute a BigQuery query to fetch the top 5 most popular male names
bq query --use_legacy_sql=false <<EOF
#standardSQL
SELECT
  name, count
FROM
  \`babynames.names_2014\`
WHERE
  gender = 'M'
ORDER BY count DESC
LIMIT 5;
EOF

# Display completion message
echo "${RED}${BOLD}Congratulations${RESET} ${WHITE}${BOLD}for${RESET} ${GREEN}${BOLD}Completing the Lab !!!${RESET}"
echo "${RED}${BOLD}Subscribe${RESET} ${WHITE}${BOLD}for${RESET} ${GREEN}${BOLD}Cloud Goodies Channel !!!${RESET}"

#------------------------------------------- Script End --------------------------------------------------#
