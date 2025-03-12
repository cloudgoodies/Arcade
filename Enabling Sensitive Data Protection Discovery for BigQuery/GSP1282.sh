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

# Step 1: Get TEMPLATE_ID
echo "${BLUE}${BOLD}Fetching TEMPLATE_ID from Google Cloud DLP API${RESET}"
export TEMPLATE_ID=$(curl -s \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json" \
"https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/locations/global/inspectTemplates" | jq -r '.inspectTemplates[0].name')

# Step 2: Create an inspection template JSON file
echo "${MAGENTA}${BOLD}Creating inspection_template.json${RESET}"
cat <<EOF > inspection_template.json
{
  "inspectTemplate": {
    "displayName": "Inspection Template for US SSN",
    "description": "This template was created as part of a Sensitive Data Protection profiler configuration and was modified for deeper inspection for US Social Security numbers.",
    "inspectConfig": {
      "infoTypes": [
        {
          "name": "US_SOCIAL_SECURITY_NUMBER"
        }
      ],
      "minLikelihood": "UNLIKELY"
    }
  }
}
EOF

# Step 3: Updating the inspection template
echo "${CYAN}${BOLD}Updating the inspection template using Google Cloud API${RESET}"
curl -X PATCH -s \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json" \
-d @inspection_template.json \
"https://dlp.googleapis.com/v2/$TEMPLATE_ID"

# Step 4: Create a de-identification template JSON file
echo "${YELLOW}${BOLD}Creating deidentify-template.json${RESET}"
cat <<EOF > deidentify-template.json
{
  "deidentifyTemplate": {
    "deidentifyConfig": {
      "recordTransformations": {
        "fieldTransformations": [
          {
            "fields": [
              {
                "name": "ssn"
              },
              {
                "name": "email"
              }
            ],
            "primitiveTransformation": {
              "replaceConfig": {
                "newValue": {
                  "stringValue": "[redacted]"
                }
              }
            }
          },
          {
            "fields": [
              {
                "name": "message"
              }
            ],
            "infoTypeTransformations": {
              "transformations": [
                {
                  "primitiveTransformation": {
                    "replaceWithInfoTypeConfig": {}
                  }
                }
              ]
            }
          }
        ]
      }
    },
    "displayName": "De-identification Template for US SSN"
  },
  "locationId": "global",
  "templateId": "us_ssn_deidentify"
}
EOF

# Step 5: Create the de-identification template in Google Cloud
echo "${RED}${BOLD}Creating the de-identification template using Google Cloud API${RESET}"
curl -X POST -s \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json" \
-d @deidentify-template.json \
"https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/locations/global/deidentifyTemplates"

# Step 6: Creating the job configuration JSON file
echo "${GREEN}${BOLD}Creating job-configuration.json${RESET}"
cat > job-configuration.json << EOM
{
  "jobId": "us_ssn_inspection",
  "inspectJob": {
    "actions": [
      {
        "saveFindings": {
          "outputConfig": {
            "table": {
              "projectId": "$DEVSHELL_PROJECT_ID",
              "datasetId": "cloudstorage_inspection",
              "tableId": "us_ssn"
            }
          }
        }
      },
      {
        "publishSummaryToCscc": {}
      }
    ],
    "inspectConfig": {
      "infoTypes": [
        {
          "name": "ADVERTISING_ID"
        },
        {
          "name": "AGE"
        },
        {
          "name": "ARGENTINA_DNI_NUMBER"
        },
        {
          "name": "AUSTRALIA_TAX_FILE_NUMBER"
        },
        {
          "name": "BELGIUM_NATIONAL_ID_CARD_NUMBER"
        },
        {
          "name": "BRAZIL_CPF_NUMBER"
        },
        {
          "name": "CANADA_SOCIAL_INSURANCE_NUMBER"
        },
        {
          "name": "CHILE_CDI_NUMBER"
        },
        {
          "name": "CHINA_RESIDENT_ID_NUMBER"
        },
        {
          "name": "COLOMBIA_CDC_NUMBER"
        },
        {
          "name": "CREDIT_CARD_NUMBER"
        },
        {
          "name": "CREDIT_CARD_TRACK_NUMBER"
        },
        {
          "name": "DATE_OF_BIRTH"
        },
        {
          "name": "DENMARK_CPR_NUMBER"
        },
        {
          "name": "EMAIL_ADDRESS"
        },
        {
          "name": "ETHNIC_GROUP"
        },
        {
          "name": "FDA_CODE"
        },
        {
          "name": "FINLAND_NATIONAL_ID_NUMBER"
        },
        {
          "name": "FRANCE_CNI"
        },
        {
          "name": "FRANCE_NIR"
        },
        {
          "name": "FRANCE_TAX_IDENTIFICATION_NUMBER"
        },
        {
          "name": "GENDER"
        },
        {
          "name": "GERMANY_IDENTITY_CARD_NUMBER"
        },
        {
          "name": "GERMANY_TAXPAYER_IDENTIFICATION_NUMBER"
        },
        {
          "name": "HONG_KONG_ID_NUMBER"
        },
        {
          "name": "IBAN_CODE"
        },
        {
          "name": "IMEI_HARDWARE_ID"
        },
        {
          "name": "INDIA_AADHAAR_INDIVIDUAL"
        },
        {
          "name": "INDIA_GST_INDIVIDUAL"
        },
        {
          "name": "INDIA_PAN_INDIVIDUAL"
        },
        {
          "name": "INDONESIA_NIK_NUMBER"
        },
        {
          "name": "IRELAND_PPSN"
        },
        {
          "name": "ISRAEL_IDENTITY_CARD_NUMBER"
        },
        {
          "name": "JAPAN_INDIVIDUAL_NUMBER"
        },
        {
          "name": "KOREA_RRN"
        },
        {
          "name": "MAC_ADDRESS"
        },
        {
          "name": "MEXICO_CURP_NUMBER"
        },
        {
          "name": "NETHERLANDS_BSN_NUMBER"
        },
        {
          "name": "NORWAY_NI_NUMBER"
        },
        {
          "name": "PARAGUAY_CIC_NUMBER"
        },
        {
          "name": "PASSPORT"
        },
        {
          "name": "PERSON_NAME"
        },
        {
          "name": "PERU_DNI_NUMBER"
        },
        {
          "name": "PHONE_NUMBER"
        },
        {
          "name": "POLAND_NATIONAL_ID_NUMBER"
        },
        {
          "name": "PORTUGAL_CDC_NUMBER"
        },
        {
          "name": "SCOTLAND_COMMUNITY_HEALTH_INDEX_NUMBER"
        },
        {
          "name": "SINGAPORE_NATIONAL_REGISTRATION_ID_NUMBER"
        },
        {
          "name": "SPAIN_CIF_NUMBER"
        },
        {
          "name": "SPAIN_DNI_NUMBER"
        },
        {
          "name": "SPAIN_NIE_NUMBER"
        },
        {
          "name": "SPAIN_NIF_NUMBER"
        },
        {
          "name": "SPAIN_SOCIAL_SECURITY_NUMBER"
        },
        {
          "name": "STORAGE_SIGNED_URL"
        },
        {
          "name": "STREET_ADDRESS"
        },
        {
          "name": "SWEDEN_NATIONAL_ID_NUMBER"
        },
        {
          "name": "SWIFT_CODE"
        },
        {
          "name": "THAILAND_NATIONAL_ID_NUMBER"
        },
        {
          "name": "TURKEY_ID_NUMBER"
        },
        {
          "name": "UK_NATIONAL_HEALTH_SERVICE_NUMBER"
        },
        {
          "name": "UK_NATIONAL_INSURANCE_NUMBER"
        },
        {
          "name": "UK_TAXPAYER_REFERENCE"
        },
        {
          "name": "URUGUAY_CDI_NUMBER"
        },
        {
          "name": "US_BANK_ROUTING_MICR"
        },
        {
          "name": "US_EMPLOYER_IDENTIFICATION_NUMBER"
        },
        {
          "name": "US_HEALTHCARE_NPI"
        },
        {
          "name": "US_INDIVIDUAL_TAXPAYER_IDENTIFICATION_NUMBER"
        },
        {
          "name": "US_SOCIAL_SECURITY_NUMBER"
        },
        {
          "name": "VEHICLE_IDENTIFICATION_NUMBER"
        },
        {
          "name": "VENEZUELA_CDI_NUMBER"
        },
        {
          "name": "WEAK_PASSWORD_HASH"
        },
        {
          "name": "AUTH_TOKEN"
        },
        {
          "name": "AWS_CREDENTIALS"
        },
        {
          "name": "AZURE_AUTH_TOKEN"
        },
        {
          "name": "BASIC_AUTH_HEADER"
        },
        {
          "name": "ENCRYPTION_KEY"
        },
        {
          "name": "GCP_API_KEY"
        },
        {
          "name": "GCP_CREDENTIALS"
        },
        {
          "name": "JSON_WEB_TOKEN"
        },
        {
          "name": "HTTP_COOKIE"
        },
        {
          "name": "XSRF_TOKEN"
        }
      ],
      "minLikelihood": "POSSIBLE"
    },
    "inspectTemplateName": "$TEMPLATE_ID",
    "storageConfig": {
      "cloudStorageOptions": {
        "filesLimitPercent": 100,
        "fileTypes": [
          "TEXT_FILE",
          "CSV"
        ],
        "fileSet": {
          "url": "gs://$DEVSHELL_PROJECT_ID-input/**"
        }
      }
    }
  }
}
EOM

# Step 7: Start the inspection job
echo "${BLUE}${BOLD}Submitting the inspection job to Google Cloud DLP API${RESET}"
curl -s \
  -X POST \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  "https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/dlpJobs" \
  -d @job-configuration.json

# Step 8: Create de-identification job configuration JSON file
echo "${MAGENTA}${BOLD}Creating de-identification job configuration JSON file${RESET}"
cat > job-configuration.json << EOM
{
  "jobId": "us_ssn_deidentify",
  "inspectJob": {
    "actions": [
      {
        "deidentify": {
          "fileTypesToTransform": [
            "TEXT_FILE",
            "CSV"
          ],
          "transformationDetailsStorageConfig": {
            "table": {
              "projectId": "$DEVSHELL_PROJECT_ID",
              "datasetId": "cloudstorage_transformations",
              "tableId": "deidentify_ssn_csv"
            }
          },
          "transformationConfig": {
            "structuredDeidentifyTemplate": "projects/$DEVSHELL_PROJECT_ID/locations/global/deidentifyTemplates/us_ssn_deidentify"
          },
          "cloudStorageOutput": "gs://$DEVSHELL_PROJECT_ID-output"
        }
      }
    ],
    "inspectConfig": {
      "infoTypes": [
        {
          "name": "ADVERTISING_ID"
        },
        {
          "name": "AGE"
        },
        {
          "name": "ARGENTINA_DNI_NUMBER"
        },
        {
          "name": "AUSTRALIA_TAX_FILE_NUMBER"
        },
        {
          "name": "BELGIUM_NATIONAL_ID_CARD_NUMBER"
        },
        {
          "name": "BRAZIL_CPF_NUMBER"
        },
        {
          "name": "CANADA_SOCIAL_INSURANCE_NUMBER"
        },
        {
          "name": "CHILE_CDI_NUMBER"
        },
        {
          "name": "CHINA_RESIDENT_ID_NUMBER"
        },
        {
          "name": "COLOMBIA_CDC_NUMBER"
        },
        {
          "name": "CREDIT_CARD_NUMBER"
        },
        {
          "name": "CREDIT_CARD_TRACK_NUMBER"
        },
        {
          "name": "DATE_OF_BIRTH"
        },
        {
          "name": "DENMARK_CPR_NUMBER"
        },
        {
          "name": "EMAIL_ADDRESS"
        },
        {
          "name": "ETHNIC_GROUP"
        },
        {
          "name": "FDA_CODE"
        },
        {
          "name": "FINLAND_NATIONAL_ID_NUMBER"
        },
        {
          "name": "FRANCE_CNI"
        },
        {
          "name": "FRANCE_NIR"
        },
        {
          "name": "FRANCE_TAX_IDENTIFICATION_NUMBER"
        },
        {
          "name": "GENDER"
        },
        {
          "name": "GERMANY_IDENTITY_CARD_NUMBER"
        },
        {
          "name": "GERMANY_TAXPAYER_IDENTIFICATION_NUMBER"
        },
        {
          "name": "HONG_KONG_ID_NUMBER"
        },
        {
          "name": "IBAN_CODE"
        },
        {
          "name": "IMEI_HARDWARE_ID"
        },
        {
          "name": "INDIA_AADHAAR_INDIVIDUAL"
        },
        {
          "name": "INDIA_GST_INDIVIDUAL"
        },
        {
          "name": "INDIA_PAN_INDIVIDUAL"
        },
        {
          "name": "INDONESIA_NIK_NUMBER"
        },
        {
          "name": "IRELAND_PPSN"
        },
        {
          "name": "ISRAEL_IDENTITY_CARD_NUMBER"
        },
        {
          "name": "JAPAN_INDIVIDUAL_NUMBER"
        },
        {
          "name": "KOREA_RRN"
        },
        {
          "name": "MAC_ADDRESS"
        },
        {
          "name": "MEXICO_CURP_NUMBER"
        },
        {
          "name": "NETHERLANDS_BSN_NUMBER"
        },
        {
          "name": "NORWAY_NI_NUMBER"
        },
        {
          "name": "PARAGUAY_CIC_NUMBER"
        },
        {
          "name": "PASSPORT"
        },
        {
          "name": "PERSON_NAME"
        },
        {
          "name": "PERU_DNI_NUMBER"
        },
        {
          "name": "PHONE_NUMBER"
        },
        {
          "name": "POLAND_NATIONAL_ID_NUMBER"
        },
        {
          "name": "PORTUGAL_CDC_NUMBER"
        },
        {
          "name": "SCOTLAND_COMMUNITY_HEALTH_INDEX_NUMBER"
        },
        {
          "name": "SINGAPORE_NATIONAL_REGISTRATION_ID_NUMBER"
        },
        {
          "name": "SPAIN_CIF_NUMBER"
        },
        {
          "name": "SPAIN_DNI_NUMBER"
        },
        {
          "name": "SPAIN_NIE_NUMBER"
        },
        {
          "name": "SPAIN_NIF_NUMBER"
        },
        {
          "name": "SPAIN_SOCIAL_SECURITY_NUMBER"
        },
        {
          "name": "STORAGE_SIGNED_URL"
        },
        {
          "name": "STREET_ADDRESS"
        },
        {
          "name": "SWEDEN_NATIONAL_ID_NUMBER"
        },
        {
          "name": "SWIFT_CODE"
        },
        {
          "name": "THAILAND_NATIONAL_ID_NUMBER"
        },
        {
          "name": "TURKEY_ID_NUMBER"
        },
        {
          "name": "UK_NATIONAL_HEALTH_SERVICE_NUMBER"
        },
        {
          "name": "UK_NATIONAL_INSURANCE_NUMBER"
        },
        {
          "name": "UK_TAXPAYER_REFERENCE"
        },
        {
          "name": "URUGUAY_CDI_NUMBER"
        },
        {
          "name": "US_BANK_ROUTING_MICR"
        },
        {
          "name": "US_EMPLOYER_IDENTIFICATION_NUMBER"
        },
        {
          "name": "US_HEALTHCARE_NPI"
        },
        {
          "name": "US_INDIVIDUAL_TAXPAYER_IDENTIFICATION_NUMBER"
        },
        {
          "name": "US_SOCIAL_SECURITY_NUMBER"
        },
        {
          "name": "VEHICLE_IDENTIFICATION_NUMBER"
        },
        {
          "name": "VENEZUELA_CDI_NUMBER"
        },
        {
          "name": "WEAK_PASSWORD_HASH"
        },
        {
          "name": "AUTH_TOKEN"
        },
        {
          "name": "AWS_CREDENTIALS"
        },
        {
          "name": "AZURE_AUTH_TOKEN"
        },
        {
          "name": "BASIC_AUTH_HEADER"
        },
        {
          "name": "ENCRYPTION_KEY"
        },
        {
          "name": "GCP_API_KEY"
        },
        {
          "name": "GCP_CREDENTIALS"
        },
        {
          "name": "JSON_WEB_TOKEN"
        },
        {
          "name": "HTTP_COOKIE"
        },
        {
          "name": "XSRF_TOKEN"
        }
      ],
      "minLikelihood": "POSSIBLE"
    },
    "storageConfig": {
      "cloudStorageOptions": {
        "filesLimitPercent": 100,
        "fileTypes": [
          "TEXT_FILE",
          "CSV"
        ],
        "fileSet": {
          "regexFileSet": {
            "bucketName": "$DEVSHELL_PROJECT_ID-input",
            "includeRegex": [],
            "excludeRegex": [
              "ignore"
            ]
          }
        }
      }
    }
  }
}
EOM

# Step 9: Submit the de-identification job
echo "${CYAN}${BOLD}Submitting the de-identification job to Google Cloud DLP API${RESET}"
curl -s \
  -X POST \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  "https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/dlpJobs" \
  -d @job-configuration.json

echo

# Function to display a random congratulatory message
function random_congrats() {
    MESSAGES=(
        "${GREEN}Congratulations For Completing The Lab! Keep up the great work!${RESET}"
        "${CYAN}Well done! Your hard work and effort have paid off!${RESET}"
        "${YELLOW}Amazing job! You’ve successfully completed the lab!${RESET}"
        "${MAGENTA}You’ve achieved something great today! Keep it up!${RESET}"
        "${RED}You’ve made remarkable progress! This is just the start!${RESET}"
    )

    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

# Display a random congratulatory message
random_congrats

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
