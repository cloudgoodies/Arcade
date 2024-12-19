# Configuring Traffic Blocklisting with Google Cloud Armor

#### ⚠️ Disclaimer :
- **This script is for the educational purposes just to show how quickly we can solve lab. Please make sure that you have a thorough understanding of the instructions before utilizing any scripts. We do not promote cheating or  misuse of resources. Our objective is to assist you in mastering the labs with efficiency, while also adhering to both 'qwiklabs' terms of services and YouTube's community guidelines.**



```
export ZONE=
```

```
gcloud compute instances create access-test --zone=$ZONE
gcloud compute ssh access-test --zone=$ZONE --command="curl -m1 {IP_ADDRESS}"
```

# Wait 5-6 minutes for task 3 check my progress.

```
gcloud compute security-policies create blocklist-access-test --description="Block access from access-test VM" && \
ACCESS_TEST_IP=$(gcloud compute instances describe access-test --zone=$ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)") && \
gcloud compute security-policies rules create 1000 --security-policy=blocklist-access-test --src-ip-ranges=$ACCESS_TEST_IP --action=deny-404 && \
gcloud compute backend-services update web-backend --security-policy=blocklist-access-test --global
```

```
gcloud compute ssh access-test --zone=$ZONE --command="curl -m1 {IP_ADDRESS}"
```


