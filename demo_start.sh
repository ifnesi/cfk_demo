#!/bin/bash

# Global variables
NAMESPACE="confluent"

# Functions
verifyPods() {
    # Function to wait for the pod(s) to be created and ready
    sleep 2
    while [ $(kubectl get pods -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}' | grep -c False) -ne 0 ]
    do
        echo "Waiting for pod(s) to be ready..."
        sleep 5
    done

    echo "Pod(s) are ready"
    kubectl get pods --namespace $NAMESPACE
    echo ""
    sleep 3
}

# Set namespace
kubectl config set-context --current --namespace=$NAMESPACE

# Wait for docker to be running
if (! docker stats --no-stream ); then
    open /Applications/Docker.app
    # Wait until Docker daemon is running and has completed initialisation
    while (! docker stats --no-stream )
    do
        # Docker takes a few seconds to initialize
        echo "Waiting for Docker to launch..."
        sleep 1
    done
    sleep 10
fi

# Install Confluent Operator
echo ""
echo "--------------------------------"
echo "1. Installing Confluent Operator"
echo "--------------------------------"
helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes --namespace $NAMESPACE
verifyPods

# Create Confluent Platform pods
echo ""
echo "-----------------------------------"
echo "2. Creating Confluent Platform pods"
echo "-----------------------------------"
kubectl apply -f confluent-platform.yaml --namespace $NAMESPACE
verifyPods

# Create Datagen connectors
echo ""
echo "------------------------------"
echo "3. Creating Datagen connectors"
echo "------------------------------"
kubectl apply -f confluent-datagen-connectors.yaml --namespace $NAMESPACE
verifyPods

# Install MongoDB Community edition
echo ""
echo "---------------------------------------"
echo "4. Installing MongoDB Community edition"
echo "---------------------------------------"
helm install community-operator mongodb/community-operator --namespace confluent
verifyPods
kubectl apply -f mongodb_community.yaml --namespace confluent
verifyPods
kubectl get mdbc

# Submit ksqlDB queries via HTTP
./ksql_rest.sh create_statements.sql

# Create MongoDB sink connector
echo ""
echo "----------------------------------"
echo "5. Creating MongoDB sink connector"
echo "----------------------------------"
kubectl apply -f confluent-mongodb-connector.yaml --namespace $NAMESPACE
verifyPods