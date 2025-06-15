#!/bin/bash

echo "🖥️  Starting Google Cloud VM creation..."

# Prompt user for region and zone
read -p ">> Enter the region (e.g. us-east4): " REGION
read -p ">> Enter the zone (e.g. us-east4-a): " ZONE

# Configuration variables
VM_NAME="my-vm-1"
MACHINE_TYPE="e2-standard-2"
IMAGE_PROJECT="ubuntu-os-cloud"
IMAGE_NAME="ubuntu-2004-focal-v20240604"  # Update this if needed

# Set gcloud default region and zone
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

# Create the VM
echo "🛠️  Creating VM..."
if gcloud compute instances create "$VM_NAME" \
  --machine-type="$MACHINE_TYPE" \
  --image="$IMAGE_NAME" \
  --image-project="$IMAGE_PROJECT" \
  --boot-disk-type=pd-balanced \
  --boot-disk-size=10GB \
  --boot-disk-device-name="$VM_NAME" \
  --zone="$ZONE"; then
    echo "✅ VM '$VM_NAME' successfully created in $ZONE using image $IMAGE_NAME."
else
    echo "❌ Failed to create VM. Please check your configuration and try again."
fi
