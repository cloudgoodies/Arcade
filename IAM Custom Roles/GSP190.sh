# Define text and background colors
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

BOLD=$(tput bold)
RESET=$(tput sgr0)

#---------------------------------------------------- START --------------------------------------------------#

echo "${GREEN}${BOLD}>> Starting Execution...${RESET}"

# Create the role-definition.yaml file
cat <<EOF > role-definition.yaml
title: "Role Editor"
description: "Edit access for App Versions"
stage: "ALPHA"
includedPermissions:
- appengine.versions.create
- appengine.versions.delete
EOF

gcloud iam roles create editor --project "$DEVSHELL_PROJECT_ID" \
--file role-definition.yaml

gcloud iam roles create viewer --project "$DEVSHELL_PROJECT_ID" \
--title "Role Viewer" --description "Custom role description." \
--permissions compute.instances.get,compute.instances.list --stage ALPHA

# Create and update a new role-definition.yaml file
cat <<EOF > new-role-definition.yaml
description: Edit access for App Versions
etag:
includedPermissions:
- appengine.versions.create
- appengine.versions.delete
- storage.buckets.get
- storage.buckets.list
name: projects/$DEVSHELL_PROJECT_ID/roles/editor
stage: ALPHA
title: Role Editor
EOF

gcloud iam roles update editor --project "$DEVSHELL_PROJECT_ID" \
--file new-role-definition.yaml --quiet

gcloud iam roles update viewer --project "$DEVSHELL_PROJECT_ID" \
--add-permissions storage.buckets.get,storage.buckets.list

gcloud iam roles update viewer --project "$DEVSHELL_PROJECT_ID" \
--stage DISABLED

# Delete and undelete the viewer role
gcloud iam roles delete viewer --project "$DEVSHELL_PROJECT_ID"

gcloud iam roles undelete viewer --project "$DEVSHELL_PROJECT_ID"

# Completion message
echo "${GREEN}${BOLD}>> Congratulations${RESET} ${WHITE}${BOLD}for${RESET} ${GREEN}${BOLD}Completing the Lab!${RESET}"

#----------------------------------------------------- END ----------------------------------------------------------#
