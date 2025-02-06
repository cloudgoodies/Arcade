# Define colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Fetching region...${NC}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo -e "${GREEN}Region set to:${NC} $REGION"

echo -e "${CYAN}Fetching zone...${NC}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
echo -e "${GREEN}Zone set to:${NC} $ZONE"

echo -e "${CYAN}Fetching project ID...${NC}"
PROJECT_ID=$(gcloud config get-value project)
echo -e "${GREEN}Project ID set to:${NC} $PROJECT_ID"

echo -e "${CYAN}Creating BigQuery dataset...${NC}"
bq mk --location=$REGION sports
echo -e "${GREEN}BigQuery dataset 'sports' created in region:${NC} $REGION"
