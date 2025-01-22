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

#---------------------------------------------------- Script Start --------------------------------------------------#

echo "${CYAN}${BOLD}Initializing...${RESET}" "${YELLOW}${BOLD}Preparing environment${RESET}"

# Create dataset
echo "${MAGENTA}${BOLD}Creating dataset:${RESET} ${GREEN}ecommerce${RESET}"
bq mk --dataset $DEVSHELL_PROJECT_ID:ecommerce

# Execute BigQuery commands with colorful prompts for clarity
echo "${BLUE}${BOLD}Executing:${RESET} ${WHITE}Copy one day of ecommerce data (08/01/2017) into a new table.${RESET}"
bq query --use_legacy_sql=false "
#standardSQL
CREATE OR REPLACE TABLE ecommerce.all_sessions_raw_20170801
#schema
(
  fullVisitorId STRING OPTIONS(description='Unique visitor ID'),
  channelGrouping STRING OPTIONS(description='Channel e.g. Direct, Organic, Referral...')
)
OPTIONS(
   description='Raw data from analyst team into our dataset for 08/01/2017'
) AS
SELECT fullVisitorId, city FROM \`data-to-insights.ecommerce.all_sessions_raw\`
WHERE date = '20170801';
"

echo "${YELLOW}${BOLD}Executing:${RESET} ${WHITE}Creating table with revenue information.${RESET}"
bq query --use_legacy_sql=false "
#standardSQL
CREATE OR REPLACE TABLE ecommerce.all_sessions_raw_20170801
#schema
(
  fullVisitorId STRING NOT NULL OPTIONS(description='Unique visitor ID'),
  channelGrouping STRING NOT NULL OPTIONS(description='Channel e.g. Direct, Organic, Referral...'),
  totalTransactionRevenue INT64 OPTIONS(description='Revenue * 10^6 for the transaction')
)
OPTIONS(
   description='Raw data from analyst team into our dataset for 08/01/2017'
) AS
SELECT fullVisitorId, channelGrouping, totalTransactionRevenue FROM \`data-to-insights.ecommerce.all_sessions_raw\`
WHERE date = '20170801';
"

echo "${MAGENTA}${BOLD}Creating:${RESET} ${WHITE}Revenue transactions table for 08/01/2017.${RESET}"
bq query --use_legacy_sql=false "
#standardSQL
CREATE OR REPLACE TABLE ecommerce.revenue_transactions_20170801
#schema
(
  fullVisitorId STRING NOT NULL OPTIONS(description='Unique visitor ID'),
  visitId STRING NOT NULL OPTIONS(description='ID of the session, not unique across all users'),
  channelGrouping STRING NOT NULL OPTIONS(description='Channel e.g. Direct, Organic, Referral...'),
  totalTransactionRevenue FLOAT64 NOT NULL OPTIONS(description='Revenue for the transaction')
)
OPTIONS(
   description='Revenue transactions for 08/01/2017'
) AS
SELECT DISTINCT
  fullVisitorId,
  CAST(visitId AS STRING) AS visitId,
  channelGrouping,
  totalTransactionRevenue / 1000000 AS totalTransactionRevenue
FROM \`data-to-insights.ecommerce.all_sessions_raw\`
WHERE date = '20170801' AND totalTransactionRevenue IS NOT NULL;
"

echo "${BLUE}${BOLD}Generating View:${RESET} ${WHITE}Latest 50 transactions.${RESET}"
bq query --use_legacy_sql=false "
CREATE OR REPLACE VIEW ecommerce.vw_latest_transactions
OPTIONS(
  description='latest 50 ecommerce transactions',
  labels=[('report_type','operational')]
)
AS
SELECT DISTINCT
  date,
  fullVisitorId,
  CAST(visitId AS STRING) AS visitId,
  channelGrouping,
  totalTransactionRevenue / 1000000 AS totalTransactionRevenue
FROM \`data-to-insights.ecommerce.all_sessions_raw\`
WHERE totalTransactionRevenue IS NOT NULL
ORDER BY date DESC
LIMIT 50;
"

echo "${MAGENTA}${BOLD}Creating View:${RESET} ${WHITE}Large transactions (> $1,000,000) for review.${RESET}"
bq query --use_legacy_sql=false "
#standardSQL
CREATE OR REPLACE VIEW ecommerce.vw_large_transactions
OPTIONS(
  description='large transactions for review',
  labels=[('org_unit','loss_prevention')]
)
AS
SELECT DISTINCT
  date,
  fullVisitorId,
  visitId,
  channelGrouping,
  totalTransactionRevenue / 1000000 AS revenue,
  STRING_AGG(DISTINCT v2ProductName ORDER BY v2ProductName LIMIT 10) AS products_ordered
FROM \`data-to-insights.ecommerce.all_sessions_raw\`
WHERE (totalTransactionRevenue / 1000000) > 1000
AND currencyCode = 'USD'
GROUP BY 1,2,3,4,5
ORDER BY date DESC
LIMIT 10;
"

echo "${GREEN}${BOLD}Success:${RESET} ${WHITE}Views and tables created.${RESET}"

#----------------------------------------------------- Script End -----------------------------------------------------#

echo "${BG_GREEN}${WHITE}${BOLD}Congratulations${RESET}" "${BG_BLUE}${WHITE}${BOLD}on${RESET}" "${BG_MAGENTA}${WHITE}${BOLD}Completing the Lab!${RESET}"
