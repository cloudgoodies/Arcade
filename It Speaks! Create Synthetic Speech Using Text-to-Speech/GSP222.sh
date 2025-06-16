
# Define colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Executing...${NC}"
gcloud auth list

export PROJECT_ID=$(gcloud config get-value project)

gcloud services enable texttospeech.googleapis.com

sudo apt-get install -y virtualenv

python3 -m venv venv

source venv/bin/activate

gcloud iam service-accounts create tts-qwiklab

gcloud iam service-accounts keys create tts-qwiklab.json --iam-account tts-qwiklab@$PROJECT_ID.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS=tts-qwiklab.json

echo -e "${GREEN}Congratulation to Complete this Lab!!${NC}"
