#!/bin/bash

# Global variables
YAML_FILE="confluent-platform.yaml"
NAMESPACE="confluent"

# Get current number of Kafka replicas
replicas=$(grep '# scale kafka' $YAML_FILE | awk '{print $2}')

# Validate input arguments
if [ $# -eq 0 ]; then
    echo "ERROR: Missing argument"
    factor=0
elif [ $1 == '-u' ]; then # up
    factor=1
elif [ $1 == '-d' ]; then # down
    factor=-1
elif [ $1 == '-c' ]; then # count
    echo "Current Kafka broker(s) count: $replicas"
    echo ""
    exit 1
elif [ $1 == '-h' ]; then # help
    factor=0
else
    echo "ERROR: Invalid argument"
    factor=0
fi
if [ $factor -eq 0 ]; then
    echo "Usage:"
    echo "  $0 -c  # view current Kafka brokers count"
    echo "  $0 -u  # scale up"
    echo "  $0 -d  # scale down"
    echo ""
    exit 1
fi

# Wait for docker to be running
if (! docker stats --no-stream > /dev/null 2>&1); then
    echo "ERROR: Please start Docker Desktop, then run the './demo_start.sh' script"
    exit 1
fi

# Check if CfK is running
if [ $(kubectl get pods | grep 'confluent-operator-849887dd4d-' | grep -c '1/1') -ne 1 ]; then
    echo "ERROR: Confluent for Kubernetes pod is not running"
    exit 1
fi

# Increment/decrement brokers
replicas_new=$((replicas + $factor))

# Update YAML file
sed -i '' "s/  replicas: $replicas  # scale kafka/  replicas: $replicas_new  # scale kafka/g" $YAML_FILE

# Apply YAML file
kubectl apply -f $YAML_FILE --namespace $NAMESPACE

echo "Kafka brokers scaled $1, from $replicas to $replicas_new"
echo "Please wait 5mins or so for changes to take effect"
echo ""