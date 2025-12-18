#  Export Data from BigQuery to Cloud Storage


#### ⚠️ Disclaimer :
- **This script is for the educational purposes just to show how quickly we can solve lab. Please make sure that you have a thorough understanding of the instructions before utilizing any scripts. We do not promote cheating or  misuse of resources. Our objective is to assist you in mastering the labs with efficiency, while also adhering to both 'qwiklabs' terms of services and YouTube's community guidelines.**

### Run the following Commands in CloudShell 

```
export PROJECT=$(gcloud config get-value project)
export BUCKET=$PROJECT-bucket
echo $BUCKET

bq load --source_format=CSV --autodetect customer_details.customers customers.csv
bq query --use_legacy_sql=false --destination_table customer_details.male_customers 'SELECT CustomerID, Gender FROM customer_details.customers WHERE Gender="Male"'
bq extract customer_details.male_customers gs://$BUCKET/exported_male_customers.csv
bq query --use_legacy_sql=false --replace --destination_table=customer_details.male_customers 'SELECT CustomerID, Gender FROM customer_details.customers WHERE Gender = "Male"'

```

### Congratulations 🎉 for completing the Lab !
