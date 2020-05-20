#! /bin/bash
echo "Running start-up script as root"
# Auto-Mount EFS Drive  
yum install -y amazon-efs-utils
MOUNTPOINT=/mnt/efs
mkdir $MOUNTPOINT
sudo mount -t efs fs-382b4792:/ $MOUNTPOINT
echo "Ephemeral disk mounted to $MOUNTPOINT"