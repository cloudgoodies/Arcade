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

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

# Step 1: Fetch the default region for resources
echo "${CYAN}${BOLD}Fetching default region...${RESET}"
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Enable IAP (Identity-Aware Proxy) service
echo "${RED}${BOLD}Enabling IAP service...${RESET}"
gcloud services enable iap.googleapis.com

# Step 3: Create a new instance template
echo "${GREEN}${BOLD}Creating an instance template...${RESET}"
gcloud compute instance-templates create instance-template-1 --project=$DEVSHELL_PROJECT_ID --machine-type=e2-micro --network-interface=network=default,network-tier=PREMIUM --metadata=^,@^startup-script=\#\ Copyright\ 2021\ Google\ LLC$'\n'\#$'\n'\#\ Licensed\ under\ the\ Apache\ License,\ Version\ 2.0\ \(the\ \"License\"\)\;$'\n'\#\ you\ may\ not\ use\ this\ file\ except\ in\ compliance\ with\ the\ License.\#\ You\ may\ obtain\ a\ copy\ of\ the\ License\ at$'\n'\#$'\n'\#\ http://www.apache.org/licenses/LICENSE-2.0$'\n'\#$'\n'\#\ Unless\ required\ by\ applicable\ law\ or\ agreed\ to\ in\ writing,\ software$'\n'\#\ distributed\ under\ the\ License\ is\ distributed\ on\ an\ \"AS\ IS\"\ BASIS,$'\n'\#\ WITHOUT\ WARRANTIES\ OR\ CONDITIONS\ OF\ ANY\ KIND,\ either\ express\ or\ implied.$'\n'\#\ See\ the\ License\ for\ the\ specific\ language\ governing\ permissions\ and$'\n'\#\ limitations\ under\ the\ License.$'\n'apt-get\ -y\ update$'\n'apt-get\ -y\ install\ git$'\n'apt-get\ -y\ install\ virtualenv$'\n'git\ clone\ https://github.com/GoogleCloudPlatform/python-docs-samples$'\n'cd\ python-docs-samples/iap$'\n'virtualenv\ venv\ -p\ python3$'\n'source\ venv/bin/activate$'\n'pip\ install\ -r\ requirements.txt$'\n'cat\ example_gce_backend.py\ \|$'\n'sed\ -e\ \"s/YOUR_BACKEND_SERVICE_ID/\$\(gcloud\ compute\ backend-services\ describe\ my-backend-service\ --global--format=\"value\(id\)\"\)/g\"\ \|$'\n'\ \ \ \ sed\ -e\ \"s/YOUR_PROJECT_ID/\$\(gcloud\ config\ get-value\ account\ \|\ tr\ -cd\ \"\[0-9\]\"\)/g\"\ \>\ real_backend.py$'\n'gunicorn\ real_backend:app\ -b\ 0.0.0.0:80,@enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --tags=http-server --create-disk=auto-delete=yes,boot=yes,device-name=instance-template-1,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/compute.readonly

# Step 4: Create a health check for the managed instance group
echo "${YELLOW}${BOLD}Creating a health check...${RESET}"
gcloud beta compute health-checks create http my-health-check \
  --project=$DEVSHELL_PROJECT_ID \
  --port=80 \
  --request-path=/ \
  --check-interval=5 \
  --timeout=5 \
  --unhealthy-threshold=2 \
  --healthy-threshold=2

# Step 5: Create a managed instance group
echo "${BLUE}${BOLD}Creating a managed instance group...${RESET}"
gcloud beta compute instance-groups managed create my-managed-instance-group \
  --project=$DEVSHELL_PROJECT_ID \
  --base-instance-name=my-managed-instance-group \
  --size=1 \
  --template=instance-template-1 \
  --region=$REGION \
  --health-check=my-health-check \
  --initial-delay=300

# Step 6: Generate SSL certificate
echo "${MAGENTA}${BOLD}Generating SSL certificate...${RESET}"
openssl genrsa -out PRIVATE_KEY_FILE 2048

cat > ssl_config <<EOF
[req]
default_bits = 2048
req_extensions = extension_requirements
distinguished_name = dn_requirements
prompt = no

[extension_requirements]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

[dn_requirements]
countryName = US
stateOrProvinceName = CA
localityName = Mountain View
0.organizationName = Cloud
organizationalUnitName = Example
commonName = Test
EOF

openssl req -new -key PRIVATE_KEY_FILE \
 -out CSR_FILE \
 -config ssl_config

openssl x509 -req \
 -signkey PRIVATE_KEY_FILE \
 -in CSR_FILE \
 -out CERTIFICATE_FILE.pem \
 -extfile ssl_config \
 -extensions extension_requirements \
 -days 365

# Step 7: Create SSL certificate in GCP
echo "${CYAN}${BOLD}Creating SSL certificate in GCP...${RESET}"
gcloud compute ssl-certificates create my-cert \
 --certificate=CERTIFICATE_FILE.pem \
 --private-key=PRIVATE_KEY_FILE \
 --global

# Step 8: Configure backend service and security policies
echo "${YELLOW}${BOLD}Configuring backend service and security policies...${RESET}"
curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "description": "Default security policy for: my-backend-service",
       "name": "default-security-policy-for-backend-service-my-backend-service",
       "rules": [
         {
           "action": "allow",
           "match": {
             "config": {
               "srcIpRanges": [
                 "*"
               ]
             },
             "versionedExpr": "SRC_IPS_V1"
           },
           "priority": 2147483647
         },
         {
           "action": "throttle",
           "description": "Default rate limiting rule",
           "match": {
             "config": {
               "srcIpRanges": [
                 "*"
               ]
             },
             "versionedExpr": "SRC_IPS_V1"
           },
           "priority": 2147483646,
           "rateLimitOptions": {
             "conformAction": "allow",
             "enforceOnKey": "IP",
             "exceedAction": "deny(403)",
             "rateLimitThreshold": {
               "count": 500,
               "intervalSec": 60
             }
           }
         }
       ]
     }' \
     "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/securityPolicies"

sleep 30

curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "backends": [
         {
           "balancingMode": "UTILIZATION",
           "capacityScaler": 1,
           "group": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'/instanceGroups/my-managed-instance-group",
           "maxUtilization": 0.8
         }
       ],
       "connectionDraining": {
         "drainingTimeoutSec": 300
       },
       "description": "",
       "enableCDN": false,
       "healthChecks": [
         "projects/'"$DEVSHELL_PROJECT_ID"'/global/healthChecks/my-health-check"
       ],
       "ipAddressSelectionPolicy": "IPV4_ONLY",
       "loadBalancingScheme": "EXTERNAL_MANAGED",
       "localityLbPolicy": "ROUND_ROBIN",
       "logConfig": {
         "enable": false
       },
       "name": "my-backend-service",
       "portName": "http",
       "protocol": "HTTP",
       "securityPolicy": "projects/'"$DEVSHELL_PROJECT_ID"'/global/securityPolicies/default-security-policy-for-backend-service-my-backend-service",
       "sessionAffinity": "NONE",
       "timeoutSec": 30
     }' \
     "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/global/backendServices"


sleep 60

curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "securityPolicy": "projects/'"$DEVSHELL_PROJECT_ID"'/global/securityPolicies/default-security-policy-for-backend-service-my-backend-service"
     }' \
     "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/backendServices/my-backend-service/setSecurityPolicy"

sleep 60

# Step 9: Create URL maps, target proxies, and forwarding rules
echo "${BLUE}${BOLD}Creating URL maps, target proxies, and forwarding rules...${RESET}"

curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "defaultService": "projects/'"$DEVSHELL_PROJECT_ID"'/global/backendServices/my-backend-service",
       "name": "my-load-balancer"
     }' \
     "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/urlMaps"


sleep 30


curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "name": "my-load-balancer-target-proxy",
       "urlMap": "projects/'"$DEVSHELL_PROJECT_ID"'/global/urlMaps/my-load-balancer"
     }' \
     "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/targetHttpProxies"

sleep 90

curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "IPAddress": "projects/'"$DEVSHELL_PROJECT_ID"'/global/addresses/my-cert",
       "IPProtocol": "TCP",
       "loadBalancingScheme": "EXTERNAL_MANAGED",
       "name": "my-load-balancer-forwarding-rule",
       "networkTier": "PREMIUM",
       "portRange": "80",
       "target": "projects/'"$DEVSHELL_PROJECT_ID"'/global/targetHttpProxies/my-load-balancer-target-proxy"
     }' \
     "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/global/forwardingRules"

sleep 30

curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "namedPorts": [
         {
           "name": "http",
           "port": 80
         }
       ]
     }' \
     "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/instanceGroups/my-managed-instance-group/setNamedPorts"

# Step 10: Provide final URLs for console access
echo "${MAGENTA}${BOLD}Access the consent screen setup here:${RESET} https://console.cloud.google.com/apis/credentials/consent?project=$DEVSHELL_PROJECT_ID"
echo "${CYAN}${BOLD}Access the IAP setup here:${RESET} https://console.cloud.google.com/security/iap?tab=applications&project=$DEVSHELL_PROJECT_ID"

# Step 11: Create details.json with developer email
echo "${RED}${BOLD}Creating details.json file...${RESET}"
# Adding one blank line
echo -e "\n"
EMAIL="$(gcloud config get-value core/account)"
cat > details.json << EOF
  App name: IAP Example
  Developer contact email: $EMAIL
EOF

# Step 12: Display details.json content
echo "${GREEN}${BOLD}Displaying details.json content...${RESET}"

cat details.json

# Adding one blank line
echo -e "\n"


# Adding one blank line
echo -e "\n"

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
