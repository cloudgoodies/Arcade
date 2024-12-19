#Configuring Traffic Blocklisting with Google Cloud Armor

```
export ZONE=
```

```
gcloud compute instances create access-test --zone=$ZONE
gcloud compute ssh access-test --zone=us-central1-a --command="curl -m1 {IP_ADDRESS}"
```


```
gcloud compute security-policies create blocklist-access-test --description="Block access from access-test VM" && \
ACCESS_TEST_IP=$(gcloud compute instances describe access-test --zone=$ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)") && \
gcloud compute security-policies rules create 1000 --security-policy=blocklist-access-test --src-ip-ranges=$ACCESS_TEST_IP --action=deny-404 && \
gcloud compute backend-services update web-backend --security-policy=blocklist-access-test --global
```

```
gcloud compute ssh access-test --zone=$ZONE --command="curl -m1 {IP_ADDRESS}"
```


