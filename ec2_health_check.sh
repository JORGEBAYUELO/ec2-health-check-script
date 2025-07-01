#!/bin/bash

# EC2 Health Check Script
# Usage: ./ec2_health_check.sh <aws-region>

REGION="$1"

if [ -z "$REGION" ]; then
  echo "Usage: $0 <aws-region>"
  exit 1
fi

echo "Checking EC2 instance health in region: $REGION"
echo "Timestamp: $(date)"
echo "------------------------------------------"

# Get instance IDs of all running EC2 instances
INSTANCE_IDS=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters Name=instance-state-name,Values=running \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text)

if [ -z "$INSTANCE_IDS" ]; then
  echo "No running EC2 instances found in region $REGION."
  exit 0
fi

# Loop through each instance and get its status
for INSTANCE_ID in $INSTANCE_IDS; do
  echo "Checking Instance ID: $INSTANCE_ID"

  SYSTEM_STATUS=$(aws ec2 describe-instance-status \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query "InstanceStatuses[0].SystemStatus.Status" \
    --output text)

  INSTANCE_STATUS=$(aws ec2 describe-instance-status \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query "InstanceStatuses[0].SystemStatus.Status" \
    --output text)

  echo "  ➤ System Status:   $SYSTEM_STATUS"
  echo "  ➤ Instance Status: $INSTANCE_STATUS"

  if [[ "SYSTEM_STATUS" == "None" || "$INSTANCE_STATUS" == "None" ]]; then
    echo " ⚠️ Status info not yet available. The instance might be too new or AWS hasn't returned full status yet."
  elif [[ "$SYSTEM_STATUS" != "ok" || "$INSTANCE_STATUS" != "ok" ]]; then
    echo "  ❌ WARNING: Instance $INSTANCE_ID is not healthy!"
  else
    echo "  ✅ Instance $INSTANCE_ID is healthy."
  fi

  echo "------------------------------------------"
done

SNS_TOPIC_ARN="arn:aws:sns:us-east-1:281156594845:ec2-health-alerts"
ALERT_MESSAGE=""
UNHEALTHY_FOUND=0

for INSTANCE_ID in $INSTANCE_IDS; do 
  SYSTEM_STATUS=$(aws ec2 describe-instance-status \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query "InstanceStatuses[0].SystemStatus.Status" \
    --output text)

  INSTANCE_STATUS=$(aws ec2 describe-instance-status \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query "InstanceStatuses[0].InstanceStatus.Status" \
    --output text)

  if [[ "$SYSTEM_STATUS" != "ok" || "$INSTANCE_STATUS" != "ok" ]]; then
    UNHEALTHY_FOUND=1
    ALERT_MESSAGE+="Instance $INSTANCE_ID is UNHEALTHY\n"
    ALERT_MESSAGE+=" System Status: $SYSTEM_STATUS\n"
    ALERT_MESSAGE+=" Instance Status: $INSTANCE_STATUS\n\n"
  fi 
done

# Publish alert if unhealthy instance(s) found
if [[ $UNHEALTHY_FOUND -eq 1 ]]; then
  aws sns publish \
    --topic-arn "$SNS_TOPIC_ARN" \
    --message "$ALERT_MESSAGE" \
    --subject "[ALERT] Unhealthy EC2 Instance(s) in $REGION"
fi
