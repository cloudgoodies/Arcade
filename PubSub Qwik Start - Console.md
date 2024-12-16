# PubSub Qwik Start - Console

#### ⚠️ Disclaimer :
- **This script is for the educational purposes just to show how quickly we can solve lab. Please make sure that you have a thorough understanding of the instructions before utilizing any scripts. We do not promote cheating or  misuse of resources. Our objective is to assist you in mastering the labs with efficiency, while also adhering to both 'qwiklabs' terms of services and YouTube's community guidelines.**

## Run in CloudShell and follow video:

```
gcloud pubsub topics create MyTopic && gcloud pubsub subscriptions create MySub --topic=MyTopic && gcloud pubsub topics publish MyTopic --message="Hello World" && gcloud pubsub subscriptions pull MySub --auto-ack
```
