#  Looker Studio: Qwik Start


#### ⚠️ Disclaimer :
- **This script is for the educational purposes just to show how quickly we can solve lab. Please make sure that you have a thorough understanding of the instructions before utilizing any scripts. We do not promote cheating or  misuse of resources. Our objective is to assist you in mastering the labs with efficiency, while also adhering to both 'qwiklabs' terms of services and YouTube's community guidelines.**

### Run the following Commands in CloudShell 

```
gcloud config set project <PROJECT_ID> && \
gcloud services enable bigquery.googleapis.com && \
bq ls --project_id <PROJECT_ID> && \
bq query --use_legacy_sql=false \
'SELECT start_station_name, COUNT(*) AS trip_count
 FROM `bigquery-public-data.san_francisco.bikeshare_trips`
 GROUP BY start_station_name
 ORDER BY trip_count DESC
 LIMIT 10;'

```

### Congratulations 🎉 for completing the Lab !
