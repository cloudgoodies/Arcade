BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

# Define color variables for background formatting
BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

# Define formatting variables
BOLD=$(tput bold)
RESET=$(tput sgr0)

# -------------------------------------------------- Start --------------------------------------------------

# Notify user of the start
echo "${YELLOW}${BOLD}Starting${RESET} ${GREEN}${BOLD}Execution${RESET}"

# Set the Zone and Region dynamically
ZONE=$(gcloud compute instances list --project="$DEVSHELL_PROJECT_ID" --format="value(zone)" | head -n 1)
REGION="${ZONE%-*}"

# Enable required Google Cloud services
gcloud services enable vpcaccess.googleapis.com servicenetworking.googleapis.com --project="$DEVSHELL_PROJECT_ID"

# Create a VPC Network Peering for Google-managed services
gcloud compute addresses create google-managed-services-default \
  --global \
  --purpose=VPC_PEERING \
  --prefix-length=16 \
  --description="Peering range for Google-managed services" \
  --network=default \
  --project="$DEVSHELL_PROJECT_ID"

gcloud services vpc-peerings connect \
  --service=servicenetworking.googleapis.com \
  --ranges=google-managed-services-default \
  --network=default \
  --project="$DEVSHELL_PROJECT_ID"

# Create a Cloud SQL instance for WordPress
gcloud beta sql instances create wordpress-db \
  --region="$REGION" \
  --database-version=MYSQL_5_7 \
  --root-password=subscribe_to_quicklab \
  --tier=db-n1-standard-1 \
  --storage-type=SSD \
  --storage-size=10GB \
  --network=default \
  --no-assign-ip \
  --enable-google-private-path \
  --authorized-networks=0.0.0.0/0

# Create the WordPress database
gcloud sql databases create wordpress \
  --instance=wordpress-db \
  --charset=utf8 \
  --collation=utf8_general_ci

# SSH into the proxy instance and configure Cloud SQL Proxy
gcloud compute ssh "wordpress-proxy" --zone="$ZONE" --project="$DEVSHELL_PROJECT_ID" --quiet --command "
  wget -qO cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64
  chmod +x cloud_sql_proxy
  export SQL_CONNECTION=\"$DEVSHELL_PROJECT_ID:$REGION:wordpress-db\"
  ./cloud_sql_proxy -instances=\$SQL_CONNECTION=tcp:3306 &

  # Notify user upon completion
echo "${GREEN}${BOLD}Congratulations${RESET} ${GREEN}${BOLD}for${RESET} ${GREEN}${BOLD}Completing the Lab !!!${RESET}"

# -------------------------------------------------- End --------------------------------------------------
"
