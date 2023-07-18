#!/bin/bash

# Global variables
NAMESPACE="confluent"

# Functions
verifyPods() {
    # Function to wait for the pod(s) to be created and ready
    sleep 2
    while :
    do
        echo "Waiting for pod(s) to be ready..."
        counter=0
        for i in {1..5}
        do
            if [ $(kubectl get pods -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}' | grep -c False) -ne 0 ]; then
                counter=$(($counter+1))
            fi
            sleep 1
        done
        if [ $counter -eq 0 ]; then
            break
        fi
    done

    echo ""
    echo "Pod(s) are ready:"
    kubectl get pods --namespace $NAMESPACE
    echo ""
    sleep 3
}

# Set namespace
kubectl config set-context --current --namespace=$NAMESPACE

# Wait for docker to be running
if (! docker stats --no-stream ); then
    echo "ERROR: Please start Docker Desktop"
    exit 1
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
echo ""
echo "------------------------------------"
echo "5. Submiting ksqlDB queries via HTTP"
echo "------------------------------------"
./ksql_rest.sh create_statements.sql

# Create MongoDB sink connector
echo ""
echo "----------------------------------"
echo "6. Creating MongoDB sink connector"
echo "----------------------------------"
kubectl apply -f confluent-mongodb-connector.yaml --namespace $NAMESPACE
sleep 3
echo ""
echo "Connector status:"
curl connect-bootstrap-lb.localhost:8083/connectors/mongodb-sink/status | jq

echo ""
echo "Script is completed, please go to http://controlcenter.localhost:9021 to access Confluent Control Center"
echo ""