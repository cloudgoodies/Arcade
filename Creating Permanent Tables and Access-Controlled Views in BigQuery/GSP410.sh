#!/bin/bash

# Define colors once
declare -A colors=(
  ["BLACK"]=$(tput setaf 0)
  ["RED"]=$(tput setaf 1)
  ["GREEN"]=$(tput setaf 2)
  ["YELLOW"]=$(tput setaf 3)
  ["WHITE"]=$(tput setaf 7)
  ["BOLD"]=$(tput bold)
  ["RESET"]=$(tput sgr0)
)

echo "${colors[YELLOW]}${colors[BOLD]}Starting${colors[RESET]} ${colors[GREEN]}${colors[BOLD]}Execution${colors[RESET]}"

# Create dataset
bq mk --dataset $DEVSHELL_PROJECT_ID:ecommerce

# Function to execute BigQuery queries
execute_query() {
  bq query --use_legacy_sql=false "$1"
}

# Base table structure queries
QUERIES=(
  # Create initial raw sessions table
  "CREATE OR REPLACE TABLE ecommerce.all_sessions_raw_20170801 (
    fullVisitorId STRING NOT NULL OPTIONS(description='Unique visitor ID'),
    channelGrouping STRING NOT NULL OPTIONS(description='Channel e.g. Direct, Organic, Referral...'),
    totalTransactionRevenue INT64 OPTIONS(description='Revenue * 10^6 for the transaction')
  ) OPTIONS(description='Raw data from analyst team into our dataset for 08/01/2017')
  AS SELECT fullVisitorId, channelGrouping, totalTransactionRevenue 
  FROM \`data-to-insights.ecommerce.all_sessions_raw\`
  WHERE date = '20170801'"

  # Create revenue transactions table
  "CREATE OR REPLACE TABLE ecommerce.revenue_transactions_20170801 (
    fullVisitorId STRING NOT NULL OPTIONS(description='Unique visitor ID'),
    visitId STRING NOT NULL OPTIONS(description='ID of the session, not unique across all users'),
    channelGrouping STRING NOT NULL OPTIONS(description='Channel e.g. Direct, Organic, Referral...'),
    totalTransactionRevenue FLOAT64 NOT NULL OPTIONS(description='Revenue for the transaction')
  ) OPTIONS(description='Revenue transactions for 08/01/2017')
  AS SELECT DISTINCT
    fullVisitorId,
    CAST(visitId AS STRING) AS visitId,
    channelGrouping,
    totalTransactionRevenue / 1000000 AS totalTransactionRevenue
  FROM \`data-to-insights.ecommerce.all_sessions_raw\`
  WHERE date = '20170801' AND totalTransactionRevenue IS NOT NULL"

  # Create view for latest transactions
  "CREATE OR REPLACE VIEW ecommerce.vw_latest_transactions
  OPTIONS(
    description='latest 50 ecommerce transactions',
    labels=[('report_type','operational')]
  ) AS
  SELECT DISTINCT
    date,
    fullVisitorId,
    CAST(visitId AS STRING) AS visitId,
    channelGrouping,
    totalTransactionRevenue / 1000000 AS totalTransactionRevenue
  FROM \`data-to-insights.ecommerce.all_sessions_raw\`
  WHERE totalTransactionRevenue IS NOT NULL
  ORDER BY date DESC
  LIMIT 50"

  # Create view for large transactions
  "CREATE OR REPLACE VIEW ecommerce.vw_large_transactions
  OPTIONS(
    description='large transactions for review',
    labels=[('org_unit','loss_prevention')],
    expiration_timestamp=TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
  ) AS
  SELECT DISTINCT
    SESSION_USER() AS viewer_ldap,
    REGEXP_EXTRACT(SESSION_USER(), r'@(.+)') AS domain,
    date,
    fullVisitorId,
    visitId,
    channelGrouping,
    totalTransactionRevenue / 1000000 AS totalTransactionRevenue,
    currencyCode,
    STRING_AGG(DISTINCT v2ProductName ORDER BY v2ProductName LIMIT 10) AS products_ordered
  FROM \`data-to-insights.ecommerce.all_sessions_raw\`
  WHERE
    (totalTransactionRevenue / 1000000) > 1000
    AND currencyCode = 'USD'
    AND REGEXP_EXTRACT(SESSION_USER(), r'@(.+)') IN ('qwiklabs.net')
  GROUP BY 1,2,3,4,5,6,7,8
  ORDER BY date DESC
  LIMIT 10"
)

# Execute all queries
for query in "${QUERIES[@]}"; do
  execute_query "$query"
done

echo "${colors[RED]}${colors[BOLD]}Congratulations${colors[RESET]} ${colors[WHITE]}${colors[BOLD]}for${colors[RESET]} ${colors[GREEN]}${colors[BOLD]}Completing the Lab !!!${colors[RESET]}"
