#!/bin/bash

# Global variables
NAMESPACE="confluent"

# Functions
verifyPods() {
    # Function to wait for the pod(s) to be created and ready
    sleep 2
    echo -n "Waiting for pod(s) to be ready."
    while :
    do
        echo -n "."
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
if (! docker stats --no-stream > /dev/null 2>&1); then
    echo "ERROR: Please start Docker Desktop"
    exit 1
fi

# Install Confluent Operator
echo ""
echo "--------------------------------"
echo "1. Installing Confluent Operator"
echo "--------------------------------"
helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes --namespace $NAMESPACE --set kRaftEnabled=true
verifyPods

# Create Confluent Platform pods
echo ""
echo "-----------------------------------"
echo "2. Creating Confluent Platform pods"
echo "-----------------------------------"
kubectl apply -f confluent-platform.yaml --namespace $NAMESPACE
verifyPods
echo ""
echo "Go to http://controlcenter.localhost:9021 to access Confluent Control Center"
sleep 10

# Demo app to produce data to topic producer-perf-test
echo ""
echo "----------------------------------------------------------------"
echo "3. Creating demo app to produce data to topic producer-perf-test"
echo "----------------------------------------------------------------"
kubectl apply -f producer-app-data.yaml --namespace $NAMESPACE
sleep 3

# Create Datagen connectors
echo ""
echo "------------------------------"
echo "4. Creating Datagen connectors"
echo "------------------------------"
kubectl apply -f confluent-datagen-connectors.yaml --namespace $NAMESPACE
sleep 3
echo ""
echo "Connector status:"
curl connect.localhost:8083/connectors/pageviews/status | jq
curl connect.localhost:8083/connectors/users/status | jq

# Install MongoDB Community edition
echo ""
echo "---------------------------------------"
echo "5. Installing MongoDB Community edition"
echo "---------------------------------------"
helm upgrade --install community-operator mongodb/community-operator --namespace $NAMESPACE
verifyPods
kubectl apply -f mongodb-community.yaml --namespace $NAMESPACE
verifyPods
kubectl get mdbc

# Submit ksqlDB queries via HTTP
echo ""
echo "------------------------------------"
echo "6. Submiting ksqlDB queries via HTTP"
echo "------------------------------------"
./ksql_rest.sh create_statements.sql

# Create MongoDB sink connector
echo ""
echo "----------------------------------"
echo "7. Creating MongoDB sink connector"
echo "----------------------------------"
kubectl apply -f confluent-mongodb-connector.yaml --namespace $NAMESPACE
sleep 3
echo ""
echo "Connector status:"
curl connect.localhost:8083/connectors/mongodb-sink/status | jq

echo ""
echo "Script is completed! Please go to http://controlcenter.localhost:9021 to access Confluent Control Center"
echo ""