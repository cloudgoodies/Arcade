clear

#!/bin/bash
# Define color variables

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`

# Array of color codes excluding black and white
TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

#----------------------------------------------------start--------------------------------------------------#

# Step 1: Display starting message with random colors
echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

# Step 2: Set the default compute zone
echo "${GREEN}${BOLD}Setting Default Compute Zone${RESET}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Step 3: Create a Kubernetes cluster with Managed Prometheus
echo "${CYAN}${BOLD}Creating Kubernetes Cluster with Managed Prometheus${RESET}"
gcloud beta container clusters create gmp-cluster --num-nodes=1 --zone $ZONE --enable-managed-prometheus

# Step 4: Get cluster credentials
echo "${YELLOW}${BOLD}Fetching Cluster Credentials${RESET}"
gcloud container clusters get-credentials gmp-cluster --zone $ZONE

# Step 5: Create a namespace for testing
echo "${BLUE}${BOLD}Creating Namespace 'gmp-test'${RESET}"
kubectl create ns gmp-test

# Step 6: Deploy the Flask application
echo "${MAGENTA}${BOLD}Deploying Flask Application${RESET}"
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/kyleabenson/flask_telemetry/master/gmp_prom_setup/flask_deployment.yaml

# Step 7: Deploy the Flask service
echo "${GREEN}${BOLD}Deploying Flask Service${RESET}"
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/kyleabenson/flask_telemetry/master/gmp_prom_setup/flask_service.yaml

# Step 8: Monitor metrics output for the keyword
echo "${YELLOW}${BOLD}Monitoring Metrics for 'flask_exporter_info' Keyword${RESET}"

sleep 120

url=$(kubectl get services -n gmp-test -o jsonpath='{.items[*].status.loadBalancer.ingress[0].ip}')

curl $url/metrics

# Step 9: Deploy Prometheus configuration
echo "${BLUE}${BOLD}Deploying Prometheus Configuration${RESET}"
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/kyleabenson/flask_telemetry/master/gmp_prom_setup/prom_deploy.yaml

# Step 10: Generate traffic to the Flask application
echo "${MAGENTA}${BOLD}Generating Traffic to Flask Application${RESET}"
timeout 120 bash -c -- 'while true; do curl $(kubectl get services -n gmp-test -o jsonpath="{.items[*].status.loadBalancer.ingress[0].ip}"); sleep $((RANDOM % 4)) ; done'

# Step 11: Create a Cloud Monitoring dashboard
echo "${CYAN}${BOLD}Creating Cloud Monitoring Dashboard${RESET}"
gcloud monitoring dashboards create --config='''
{
  "category": "CUSTOM",
  "displayName": "Prometheus Dashboard Example",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "height": 4,
        "widget": {
          "title": "prometheus/flask_http_request_total/counter [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"prometheus.googleapis.com/flask_http_request_total/counter\" resource.type=\"prometheus_target\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"status\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "thresholds": [],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 6,
        "xPos": 0,
        "yPos": 0
      }
    ]
  }
}
'''

echo -e "\n"  # Adding one blank line

cd

remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with "gsp", "arc", or "shell"
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            # Check if it's a regular file (not a directory)
            if [[ -f "$file" ]]; then
                # Remove the file and echo the file name
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

remove_files

echo "${GREEN}${BOLD}congrats You have completed this lab successfully!!!!"
