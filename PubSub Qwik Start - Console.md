

```
gcloud pubsub topics create MyTopic && gcloud pubsub subscriptions create MySub --topic=MyTopic && gcloud pubsub topics publish MyTopic --message="Hello World" && gcloud pubsub subscriptions pull MySub --auto-ack
```
