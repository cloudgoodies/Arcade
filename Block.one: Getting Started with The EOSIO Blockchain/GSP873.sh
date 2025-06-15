#!/bin/bash

echo "           Starting Executing....                "

# Prompt user for region and zone
read -p ">> Enter the region (e.g. us-central1): " REGION
read -p ">> Enter the zone (e.g. us-central1-a): " ZONE

VM_NAME="my-vm-1"
MACHINE_TYPE="e2-standard-2"
IMAGE_PROJECT="ubuntu-os-cloud"
IMAGE_FAMILY="ubuntu-2404-lts-minimal"

# Optional: Set gcloud config defaults
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

# Create the VM instance using image family instead of fixed image name
gcloud compute instances create "$VM_NAME" \
  --zone="$ZONE" \
  --machine-type="$MACHINE_TYPE" \
  --image-family="$IMAGE_FAMILY" \
  --image-project="$IMAGE_PROJECT" \
  --boot-disk-size=10GB \
  --boot-disk-type=pd-balanced \
  --boot-disk-device-name="$VM_NAME"

echo "✅ VM $VM_NAME creation initiated in region $REGION, zone $ZONE using image family $IMAGE_FAMILY."
