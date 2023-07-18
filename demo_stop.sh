#!/bin/bash
kubectl config set-context --current --namespace=confluent

kubectl delete -f confluent-mongodb-connector.yaml
kubectl delete -f mongodb_community.yaml
helm uninstall community-operator

kubectl delete -f confluent-datagen-connectors.yaml
kubectl delete -f confluent-platform.yaml
helm uninstall confluent-operator

while :
do
    echo "Waiting for pod(s) to be terminated..."
    counter=0
    for i in {1..5}
    do
        if [ $(kubectl get pods | grep -c "") -ne 0 ]; then
            counter=$(($counter+1))
        fi
        sleep 1
    done
    if [ $counter -eq 0 ]; then
        break
    fi
done

echo ""
