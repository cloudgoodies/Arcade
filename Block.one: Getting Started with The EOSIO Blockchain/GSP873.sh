#!/bin/bash

echo "🖥️  Starting Google Cloud VM creation..."

# Prompt user for region and zone
read -p ">> Enter the region (e.g. us-east4): " REGION
read -p ">> Enter the zone (e.g. us-east4-a): " ZONE

# Configuration variables
VM_NAME="my-vm-1"
MACHINE_TYPE="e2-standard-2"
IMAGE_PROJECT="debian-cloud"
IMAGE_FAMILY="debian-11"

# Set gcloud default region and zone
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

# Create the VM
echo "🛠️  Creating VM..."
if gcloud compute instances create "$VM_NAME" \
  --zone="$ZONE" \
  --machine-type="$MACHINE_TYPE" \
  --image-family="$IMAGE_FAMILY" \
  --image-project="$IMAGE_PROJECT" \
  --boot-disk-size=10GB \
  --boot-disk-type=pd-balanced \
  --boot-disk-device-name="$VM_NAME"; then
    echo "✅ VM '$VM_NAME' successfully created in $ZONE using image family $IMAGE_FAMILY."
else
    echo "❌ Failed to create VM. Please check your configuration and try again."
fi
