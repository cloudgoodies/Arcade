#  Analyzing Billing Data with BigQuery


#### ⚠️ Disclaimer :
- **This script is for the educational purposes just to show how quickly we can solve lab. Please make sure that you have a thorough understanding of the instructions before utilizing any scripts. We do not promote cheating or  misuse of resources. Our objective is to assist you in mastering the labs with efficiency, while also adhering to both 'qwiklabs' terms of services and YouTube's community guidelines.**

### Run the following Commands in CloudShell 

```
curl -LO raw.githubusercontent.com/cloudgoodies/Arcade/refs/heads/main/Analyzing%20Billing%20Data%20with%20BigQuery/GSP621.sh

sudo chmod +x GSP621.sh

./GSP621.sh
```

* Go to **BigQuery** from [here](https://console.cloud.google.com/bigquery?)

```
SELECT CONCAT(service.description, ' : ',sku.description) as Line_Item FROM `billing_dataset.enterprise_billing` GROUP BY 1
```
```
SELECT CONCAT(service.description, ' : ',sku.description) as Line_Item, Count(*) as NUM FROM `billing_dataset.enterprise_billing` GROUP BY CONCAT(service.description, ' : ',sku.description)
```


### Congratulations 🎉 for completing the Lab !
