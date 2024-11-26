# BASIC INSTRUCTIONS
# Set line 10 to the same value you configured your CLI to default to. Check with "aws configure list"
# make me executable with chmod +x setup-lightsail.sh
# run me with ./setup-lightsail.sh
# get instance IP address with "aws lightsail get-instance --instance-name audit-test --region us-west-2 --query 'instance.publicIpAddress' --output text"
# once done delete with "aws lightsail delete-instance --instance-name audit-test --region us-west-2 --output text"
# query with "aws lightsail get-instances --region us-west-2"
# check your region!!!


#!/bin/bash

# Set error handling
set -e

# Define variables
INSTANCE_NAME="audit-test"
REGION="us-west-2"
AVAILABILITY_ZONE="us-west-2a"

echo "Creating Lightsail instance in $AVAILABILITY_ZONE..."

# Create a Lightsail instance - redirect output to /dev/null
aws lightsail create-instances \
    --instance-names $INSTANCE_NAME \
    --availability-zone $AVAILABILITY_ZONE \
    --blueprint-id amazon_linux_2 \
    --bundle-id nano_2_0 \
    --user-data '#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
echo "<html><body><h1>Audit App Test Instance</h1></body></html>" > /var/www/html/index.html' \
    --output text > /dev/null

echo "Waiting for instance to be ready..."
sleep 60  # Wait for instance to initialize

echo "Opening HTTP port..."
# Open HTTP port for web access
aws lightsail open-instance-public-ports \
    --port-info fromPort=80,toPort=80,protocol=TCP \
    --instance-name $INSTANCE_NAME \
    --region $REGION \
    --output text > /dev/null

echo "Getting instance information..."
# Get instance information and format it nicely
aws lightsail get-instance \
    --instance-name $INSTANCE_NAME \
    --region $REGION \
    --query 'instance.{Name:name,IP:publicIpAddress,State:state.name,Zone:location.availabilityZone}' \
    --output table

echo "Setup complete! You can access your instance using the IP address shown above."