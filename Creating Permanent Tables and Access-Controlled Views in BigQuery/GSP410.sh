#!/bin/bash

# Define colors and styles
BLACK=$(tput setaf 0); RED=$(tput setaf 1); GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3); BLUE=$(tput setaf 4); MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6); WHITE=$(tput setaf 7)
BOLD=$(tput bold); RESET=$(tput sgr0)

# Display start message
echo "${YELLOW}${BOLD}Starting Execution...${RESET}"

# Create dataset
bq mk --dataset $DEVSHELL_PROJECT_ID:ecommerce

# Create and replace tables and views
bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE ecommerce.all_sessions_raw_20170801 (
  fullVisitorId STRING NOT NULL OPTIONS(description='Unique visitor ID'),
  channelGrouping STRING NOT NULL OPTIONS(description='Channel e.g. Direct, Organic, Referral...'),
  totalTransactionRevenue INT64 OPTIONS(description='Revenue * 10^6 for the transaction')
) OPTIONS(description='Raw data from analyst team for 08/01/2017') AS
SELECT fullVisitorId, channelGrouping, totalTransactionRevenue 
FROM \`data-to-insights.ecommerce.all_sessions_raw\`
WHERE date = '20170801';"

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE ecommerce.revenue_transactions_20170801 (
  fullVisitorId STRING NOT NULL OPTIONS(description='Unique visitor ID'),
  visitId STRING NOT NULL OPTIONS(description='Session ID, not unique across all users'),
  channelGrouping STRING NOT NULL OPTIONS(description='Channel e.g. Direct, Organic, Referral...'),
  totalTransactionRevenue FLOAT64 NOT NULL OPTIONS(description='Revenue for the transaction')
) OPTIONS(description='Revenue transactions for 08/01/2017') AS
SELECT DISTINCT fullVisitorId, CAST(visitId AS STRING) AS visitId, 
  channelGrouping, totalTransactionRevenue / 1000000 AS totalTransactionRevenue
FROM \`data-to-insights.ecommerce.all_sessions_raw\`
WHERE date = '20170801' AND totalTransactionRevenue IS NOT NULL;"

# Create or replace views
bq query --use_legacy_sql=false "
CREATE OR REPLACE VIEW ecommerce.vw_latest_transactions OPTIONS(
  description='Latest 50 ecommerce transactions',
  labels=[('report_type','operational')]
) AS
SELECT DISTINCT date, fullVisitorId, CAST(visitId AS STRING) AS visitId, 
  channelGrouping, totalTransactionRevenue / 1000000 AS totalTransactionRevenue
FROM \`data-to-insights.ecommerce.all_sessions_raw\`
WHERE totalTransactionRevenue IS NOT NULL
ORDER BY date DESC
LIMIT 50;"

bq query --use_legacy_sql=false "
CREATE OR REPLACE VIEW ecommerce.vw_large_transactions OPTIONS(
  description='Large transactions for review',
  labels=[('org_unit','loss_prevention')],
  expiration_timestamp=TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
) AS
SELECT DISTINCT SESSION_USER() AS viewer_ldap, REGEXP_EXTRACT(SESSION_USER(), r'@(.+)') AS domain, 
  date, fullVisitorId, visitId, channelGrouping, 
  totalTransactionRevenue / 1000000 AS totalTransactionRevenue, currencyCode,
  STRING_AGG(DISTINCT v2ProductName ORDER BY v2ProductName LIMIT 10) AS products_ordered
FROM \`data-to-insights.ecommerce.all_sessions_raw\`
WHERE (totalTransactionRevenue / 1000000) > 1000 AND currencyCode = 'USD' 
  AND REGEXP_EXTRACT(SESSION_USER(), r'@(.+)') = 'qwiklabs.net'
GROUP BY 1,2,3,4,5,6,7,8
ORDER BY date DESC
LIMIT 10;"

# Display end message
echo "${RED}${BOLD}Congratulations${RESET} ${WHITE}${BOLD}for${RESET} ${GREEN}${BOLD}completing the lab!${RESET}"
