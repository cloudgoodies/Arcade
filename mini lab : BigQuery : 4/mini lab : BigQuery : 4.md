#  mini lab : BigQuery : 4


#### ⚠️ Disclaimer :
- **This script is for the educational purposes just to show how quickly we can solve lab. Please make sure that you have a thorough understanding of the instructions before utilizing any scripts. We do not promote cheating or  misuse of resources. Our objective is to assist you in mastering the labs with efficiency, while also adhering to both 'qwiklabs' terms of services and YouTube's community guidelines.**

### Run the following Commands in CloudShell 

```
BUCKET_NAME=""
DATASET_NAME="work_day"
TABLE_NAME="employee"

bq mk $DATASET_NAME

bq mk --table $DATASET_NAME.$TABLE_NAME \
    employee_id:INTEGER,device_id:STRING,username:STRING,department:STRING,office:STRING

bq load --source_format=CSV --skip_leading_rows=1 $DATASET_NAME.$TABLE_NAME \
    gs://$BUCKET_NAME/employees.csv \
    employee_id:INTEGER,device_id:STRING,username:STRING,department:STRING,office:STRING

```

### Congratulations 🎉 for completing the Lab !
