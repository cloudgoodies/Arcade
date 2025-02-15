
gcloud config set project $PROJECT_ID && \
gcloud services enable bigquery.googleapis.com && \
bq ls --project_id $PROJECT_ID && \
bq query --use_legacy_sql=false \
'SELECT start_station_name, COUNT(*) AS trip_count
 FROM `bigquery-public-data.san_francisco.bikeshare_trips`
 GROUP BY start_station_name
 ORDER BY trip_count DESC
 LIMIT 10;'
