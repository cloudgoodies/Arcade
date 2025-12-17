#  APIs Explorer: Compute Engine


#### ⚠️ Disclaimer :
- **This script is for the educational purposes just to show how quickly we can solve lab. Please make sure that you have a thorough understanding of the instructions before utilizing any scripts. We do not promote cheating or  misuse of resources. Our objective is to assist you in mastering the labs with efficiency, while also adhering to both 'qwiklabs' terms of services and YouTube's community guidelines.**

### Run the following Commands in CloudShell 

```
bq load --source_format=CSV --skip_leading_rows=1 --autodetect DATASET.products_information gs://PROJECT-ID-bucket/products.csv
bq query --use_legacy_sql=false 'CREATE SEARCH INDEX product_search_index ON DATASET.products_information(ALL COLUMNS)'
bq query --use_legacy_sql=false 'SELECT * FROM DATASET.products_information WHERE SEARCH(products_information, "22 oz Water Bottle")'
```

### Congratulations 🎉 for completing the Lab !
