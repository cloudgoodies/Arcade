
#!/bin/bash

# Exit on error
set -e

echo "Starting Google Cloud Lab Automation Script..."

# Clone repository and navigate to folder
git clone --depth 1 https://github.com/GoogleCloudPlatform/training-data-analyst.git
cd ~/training-data-analyst/courses/design-process/deploying-apps-to-gcp

# Install dependencies and test application locally
pip3 install -r requirements.txt
python3 main.py &
sleep 5
kill $!

# Create app.yaml
echo "runtime: python312" > app.yaml

# Create App Engine application
echo "Creating App Engine application..."
gcloud app create --region=us-central

# Deploy application
echo "Deploying App Engine application..."
gcloud app deploy --version=one --quiet

# Create Alerting Policy for Latency
echo "Creating Latency Alerting Policy..."
gcloud alpha monitoring channels create --display-name="My Email" --type=email --channel-labels=email_address="your-email@example.com"

# Update main.py with delay
sed -i 's/return render_template/    time.sleep(10)\n    return render_template/' main.py

# Redeploy application with latency
echo "Redeploying application with latency..."
gcloud app deploy --version=two --quiet

# Generate load
echo "Generating load for latency testing..."
while true; do
  curl -s https://$DEVSHELL_PROJECT_ID.appspot.com/ | grep -e "<title>" -e "error"
  sleep .$((RANDOM % 10))s
done &

# Wait and allow alerts to fire
sleep 300
kill $!

# Create JSON file for HTTP error alerting policy
cat <<EOF > app-engine-error-percent-policy.json
{
    "displayName": "HTTP error count exceeds 1 percent for App Engine apps",
    "combiner": "OR",
    "conditions": [
        {
            "displayName": "Ratio: HTTP 500s error-response counts / All HTTP response counts",
            "conditionThreshold": {
                "filter": "metric.label.response_code>=\"500\" AND metric.label.response_code<\"600\" AND metric.type=\"appengine.googleapis.com/http/server/response_count\" AND resource.type=\"gae_app\"",
                "aggregations": [
                    {
                        "alignmentPeriod": "60s",
                        "crossSeriesReducer": "REDUCE_SUM",
                        "groupByFields": [
                            "project",
                            "resource.label.module_id",
                            "resource.label.version_id"
                        ],
                        "perSeriesAligner": "ALIGN_DELTA"
                    }
                ],
                "denominatorFilter": "metric.type=\"appengine.googleapis.com/http/server/response_count\" AND resource.type=\"gae_app\"",
                "denominatorAggregations": [
                    {
                        "alignmentPeriod": "60s",
                        "crossSeriesReducer": "REDUCE_SUM",
                        "groupByFields": [
                            "project",
                            "resource.label.module_id",
                            "resource.label.version_id"
                        ],
                        "perSeriesAligner": "ALIGN_DELTA"
                    }
                ],
                "comparison": "COMPARISON_GT",
                "thresholdValue": 0.01,
                "duration": "0s",
                "trigger": {
                    "count": 1
                }
            }
        }
    ]
}
EOF

# Deploy HTTP error alerting policy
gcloud alpha monitoring policies create --policy-from-file="app-engine-error-percent-policy.json"

# Update main.py for random errors
sed -i 's/return render_template/    if random.randrange(49) == 0:\n        return json.dumps({"error": "Error thrown randomly"}), 500\n    return render_template/' main.py

# Redeploy application with random errors
gcloud app deploy --version=three --quiet

# Generate load for error testing
echo "Generating load for error testing..."
while true; do
  curl -s https://$DEVSHELL_PROJECT_ID.appspot.com/ | grep -e "<title>" -e "error"
  sleep .$((RANDOM % 10))s
done &

# Wait and allow alerts to fire
sleep 300
kill $!


# Clean up notification channels and policies
echo "Cleaning up..."
gcloud alpha monitoring policies delete --all --quiet

echo "Google Cloud Lab Automation Completed!"
