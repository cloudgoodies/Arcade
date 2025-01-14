# Define text color and formatting variables
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

# ---------------------------------------------------- Start ---------------------------------------------------- #

# Start message
echo "${YELLOW}${BOLD}Starting${RESET} ${GREEN}${BOLD}Execution${RESET}"

# Create a dataset
bq mk ecommerce

# Run queries
bq query --use_legacy_sql=false '
#standardSQL
SELECT DISTINCT
  fullVisitorId,
  date,
  city,
  pageTitle
FROM `data-to-insights.ecommerce.all_sessions_raw`
WHERE date = "20170708"
LIMIT 5
'

bq query --use_legacy_sql=false '
#standardSQL
SELECT DISTINCT
  fullVisitorId,
  date,
  city,
  pageTitle
FROM `data-to-insights.ecommerce.all_sessions_raw`
WHERE date = "20180708"
LIMIT 5
'

# Create a partitioned table
bq query --use_legacy_sql=false '
CREATE OR REPLACE TABLE ecommerce.partition_by_day
PARTITION BY date_formatted
OPTIONS (
  description="A table partitioned by date"
) AS
SELECT DISTINCT
  PARSE_DATE("%Y%m%d", date) AS date_formatted,
  fullVisitorId
FROM `data-to-insights.ecommerce.all_sessions_raw`
'

# Query the partitioned table
bq query --use_legacy_sql=false '
#standardSQL
SELECT *
FROM `data-to-insights.ecommerce.partition_by_day`
WHERE date_formatted = "2016-08-01"
'

bq query --use_legacy_sql=false '
#standardSQL
SELECT *
FROM `data-to-insights.ecommerce.partition_by_day`
WHERE date_formatted = "2018-07-08"
'

# Weather data query
bq query --use_legacy_sql=false '
#standardSQL
SELECT
  DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS date,
  (SELECT ANY_VALUE(name) FROM `bigquery-public-data.noaa_gsod.stations` AS stations
   WHERE stations.usaf = stn) AS station_name,
  prcp
FROM `bigquery-public-data.noaa_gsod.gsod*` AS weather
WHERE prcp < 99.9  -- Filter unknown values
  AND prcp > 0      -- Filter stations/days with no precipitation
  AND _TABLE_SUFFIX >= "2018"
ORDER BY date DESC
LIMIT 10
'

# Create a partitioned table for days with rain
bq query --use_legacy_sql=false '
CREATE OR REPLACE TABLE ecommerce.days_with_rain
PARTITION BY date
OPTIONS (
  partition_expiration_days=60,
  description="Weather stations with precipitation, partitioned by day"
) AS
SELECT
  DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS date,
  (SELECT ANY_VALUE(name) FROM `bigquery-public-data.noaa_gsod.stations` AS stations
   WHERE stations.usaf = stn) AS station_name,
  prcp
FROM `bigquery-public-data.noaa_gsod.gsod*` AS weather
WHERE prcp < 99.9  -- Filter unknown values
  AND prcp > 0      -- Filter stations/days with precipitation
  AND _TABLE_SUFFIX >= "2018"
'

# Completion message
echo "${GREEN}${BOLD}Congratulations${RESET} ${GREEN}${BOLD}for${RESET} ${GREEN}${BOLD}Completing the Lab !!!${RESET}"

# ----------------------------------------------------- End ----------------------------------------------------- #
