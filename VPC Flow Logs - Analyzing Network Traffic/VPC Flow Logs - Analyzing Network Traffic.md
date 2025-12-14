#  VPC Flow Logs - Analyzing Network Traffic


#### ⚠️ Disclaimer :
- **This script is for the educational purposes just to show how quickly we can solve lab. Please make sure that you have a thorough understanding of the instructions before utilizing any scripts. We do not promote cheating or  misuse of resources. Our objective is to assist you in mastering the labs with efficiency, while also adhering to both 'qwiklabs' terms of services and YouTube's community guidelines.**

### Run the following Commands in CloudShell 

```
curl -LO raw.githubusercontent.com/cloudgoodies/Arcade/refs/heads/main/VPC%20Flow%20Logs%20-%20Analyzing%20Network%20Traffic/GSP212.sh

sudo chmod +x GSP212.sh

./GSP212.sh
```

### Sink Name: `vpc-flows`

```bash
export ZONE=$(gcloud compute instances list --filter="name=centos-clean" --format="value(zone)")
gcloud compute ssh centos-clean --zone=$ZONE --quiet
```

### Congratulations 🎉 for completing the Lab !
